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

            first_published = first_published.filter(:id => content.map { |c| c.id })
            published = published.filter(:id => content.map { |c| c.id })

            create_revision(revision, revision-1)
            content.each do |c|
              c.sync_to_revision(revision)
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
      push_page_change
    end

    def push_page_change
      Spontaneous::Change.push(self) if page?
    end


    def with_revision(revision, &block)
      self.class.with_revision(revision, &block)
    end
    def with_editable(&block)
      self.class.with_editable(&block)
    end

    def sync_to_revision(revision, origin=true)
      # 'publish' is a lock to make sure the duplication doesn't cross
      # page boundaries unless that's necessary (such as in the case
      # of a page addition)
      publish = origin || !self.page?

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
          Spontaneous::Content.insert({:id => self.id})
          publish = true
        end

        if publish
          with_editable do
            self.pieces.each do |entry|
              entry.sync_to_revision(revision, false)
            end
          end
          Spontaneous::Content.where(:id => self.id).update(self.values)
        end
      end
    end
  end
end
