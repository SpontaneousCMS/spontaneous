# encoding: UTF-8


module Spontaneous::Plugins
  module Publishing
    extend ActiveSupport::Concern

    module ClassMethods
      @@dataset = nil
      @@revision = nil

      def current_revision_table
        revision_table(@@revision)
      end

      def base_table
        'content'
      end

      # make sure that the table name is always the correct revision
      def simple_table
        current_revision_table
      end

      def revision_table(revision=nil)
        return base_table if revision.nil?
        "__r#{revision.to_s.rjust(5, '0')}_content"
      end

      def revision_table?(table_name)
        /^__r\d{5}_content$/ === table_name.to_s
      end

      def revision_exists?(revision)
        database.tables.include?(revision_table(revision).to_sym)
      end

      def revision
        @@revision
      end

      def with_revision(revision=nil, &block)
        saved_revision = @@revision
        @@revision = revision
        self.with_table(revision_table(revision), &block)
      ensure
        @@revision = saved_revision
      end

      def with_editable(&block)
        with_revision(nil, &block)
      end

      def with_published(&block)
        revision = Spontaneous::Site.published_revision
        with_revision(revision, &block)
      end

      def database
        Spontaneous.database
      end

      ##
      # Publish a revision
      #
      # If content is a non-empty list of Content ids then this will only publish changes to those
      # rows (taking the rest of the content from the previous revision)
      # Pass in a block if you want to tie some bit of post processing to the success or failure
      # of the publish step (used in the site render stage for example)
      def publish(revision, content=nil)
        mark_first_published = Proc.new do |dataset|
          dataset.update(:first_published_at => Sequel.datetime_class.now, :first_published_revision => revision)
        end

        mark_published = Proc.new do |dataset|
          dataset.update(:last_published_at => Sequel.datetime_class.now)
        end

        first_published = published = nil

        db.transaction do
          with_editable do
            first_published = self.filter(:first_published_at => nil)
            published = self.filter

            must_publish_all = (content.nil? || (!revision_exists?(revision-1)) || \
                                (content.is_a?(Array) && content.empty?))

            if must_publish_all
              create_revision(revision)
            else
              content = content.map do |c|
                c.is_a?(Spontaneous::Content) ? c.reload : Spontaneous::Content.first(:id => c)
              end.compact

              # pages should be published in depth order because its possible to be publishing a child of
              # a page that's never been published
              content.sort! { |c1, c2| c1.depth <=> c2.depth }

              first_published = first_published.filter(:id => content.map { |c| c.id })
              published = published.filter(:id => content.map { |c| c.id })

              create_revision(revision, revision-1)
              content.each do |c|
                c.sync_to_revision(revision, true)
              end
            end

            # run any passed code and if it fails revert the publish step
            if block_given?
              begin
                with_revision(revision) { yield }
              rescue Exception => e
                delete_revision(revision)
                raise e
              end
            end

            with_editable do
              mark_first_published[first_published]
              mark_published[published]
            end
            with_revision(revision) do
              mark_first_published[first_published]
              mark_published[published]
            end
          end
        end
      end

      def publish_all(revision, &block)
        publish(revision, nil, &block)
      end

      def create_revision(revision, from_revision=nil)
        dest_table = revision_table(revision)
        src_table = revision_table(from_revision)
        sql = "CREATE TABLE #{dataset.quote_identifier(dest_table)} AS SELECT * FROM #{dataset.quote_identifier(src_table)}"
        database.run(sql)
        indexes = database.indexes(base_table)
        indexes.each do |name, options|
          columns = options.delete(:columns)
          database.add_index(dest_table, columns, options)
        end
      end

      def delete_revision(revision)
        return if revision.nil?
        database.drop_table(revision_table(revision)) if revision_exists?(revision)
      end

      def delete_all_revisions!
        database.tables.each do |table|
          database.drop_table(table) if revision_table?(table)
        end
      end
    end # ClassMethods

    # InstanceMethods

    def after_create
      super
      page.modified!(page?) if page
    end

    def after_update
      super
      page.modified!(page?) if page
    end

    def modified!(caller_is_page)
      unless caller_is_page
        self.model.where(:id => self.id).update(:modified_at => Sequel.datetime_class.now)
      end
    end

    def with_revision(revision, &block)
      self.class.with_revision(revision, &block)
    end
    def with_editable(&block)
      self.class.with_editable(&block)
    end

    def never_published?
      first_published_at.nil?
    end

    def before_publish(revision); end
    def after_publish(revision);  end

    def sync_to_revision(revision, origin=false)
      # 'publish' is a lock to make sure the duplication doesn't cross
      # page boundaries unless that's necessary (such as in the case
      # of a page addition)
      publish = origin || !self.page?
      first_publish = false

      with_revision(revision) do
        published_copy = Spontaneous::Content.first(:id => self.id)
        if published_copy
          if publish and published_copy.entry_store
            pieces_to_delete = published_copy.entry_store - self.entry_store
            pieces_to_delete.each do |entry|
              if c = Spontaneous::Content.first(:id => entry[0])
                c.destroy(false) rescue ::Sequel::NoExistingObject
              end
            end
          end
        else # missing content (so force a publish)
          Spontaneous::Content.insert({:id => self.id, :type_sid => values[:type_sid]})
          publish = true
          first_publish = true
        end

        if publish
          self.before_publish(revision)
          with_editable do
            self.pieces.each do |entry|
              entry.sync_to_revision(revision, false)
            end
          end

          if self.page?
            sync_children_to_revision(revision)
          end

          Spontaneous::Content.where(:id => self.id).update(values)

          published_values = {}
          # ancestors can have un-published changes to their paths so we can't just directly publish the current path.
          # Instead we re-calculate our path using the published version of the ancestor's path & our (potentially) updated slug.
          if self.page?
            published = self.class.first :id => self.id
            published_values[:path] = published.calculate_path_with_slug(values[:slug])
          end

          # need to calculate the correct visibility for published items. I can't just take this from the editable
          # content because up-tree visibility changes might not have been published. This kinda mess is why individual
          # page publishing is a pain.

          published_values[:hidden] = self.recalculated_hidden

          Spontaneous::Content.where(:id => self.id).update(published_values)

          # Pages that haven't been published before can be published independently of their parents.
          # In that case we need to insert an entry for them. We can't guarantee that the published
          # parent has the same entries
          insert_entry_for_new_page(revision) if first_publish && page?
          self.after_publish(revision)
        end
      end
    end

    def sync_children_to_revision(revision)
      published_children = with_revision(revision) { S::Content.filter(:parent_id => self.id) }
      published_children.each do |child_page|
        deleted = with_editable { S::Content.select(:id).first(:id => child_page.id).nil? }
        if deleted
          with_revision(revision) do
            child_page.destroy
          end
        end
      end
    end

    # Finds an entry in the parent page and duplicates it to the parent
    # of the newly published page. Positions are not exact as other child pages might not have
    # been published.
    def insert_entry_for_new_page(revision)
      detect_entry = proc { |e| e[0] == self.id }

      parent_entry_store = with_editable { self.parent.entry_store.dup }
      entry = parent_entry_store.find(&detect_entry)
      index = parent_entry_store.index(&detect_entry)
      published_parent = Spontaneous::Content.first :id => parent_id

      published_parent.entry_store ||= []

      unless published_parent.entry_store.find(&detect_entry)
        published_parent.entry_store.insert(index, entry).compact!
      end
      published_parent.save
    end
  end
end
