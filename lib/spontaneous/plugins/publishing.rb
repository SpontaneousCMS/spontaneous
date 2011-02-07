# encoding: UTF-8

# is this unforgivable?
# i think it's kinda neat, if a tad fragile (to columns named 'content'...)
module Sequel
  class Dataset
    alias_method :sequel_quote_identifier, :quote_identifier


    def quote_identifier(name)
      if name == :content or name == "content"
        name = Spontaneous::Content.current_revision_table
      end
      sequel_quote_identifier(name)
    end
  end
end

module Spontaneous::Plugins
  module Publishing

    module ClassMethods
      @@dataset = nil
      @@revision = nil
      @@publishable_classes = [Spontaneous::Content]

      def inherited(subclass)
        super
        add_publishable_class(subclass)
      end


      def add_publishable_class(klass)
        @@publishable_classes << klass unless @@publishable_classes.include?(klass)
      end

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

      def reset_revision
        @@revision, @@dataset = revision_stack.first
        revision_stack.clear
      end

      def with_revision(revision=nil, &block)
        revision_push(revision)
        begin
          yield
        ensure
          revision_pop
        end if block_given?
      end

      def with_editable(&block)
        with_revision(nil, &block)
      end

      def with_published(&block)
        revision = Spontaneous::Site.published_revision
        with_revision(revision, &block)
      end

      def revision_push(revision)
        revision_stack.push([@@revision, (@@dataset || self.dataset)])
        @@dataset = revision_dataset(revision)
        @@revision = revision
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
      def publish(revision, content=nil, &block)
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
              c.is_a?(Spontaneous::Content) ? c.reload : Spontaneous::Content[c]
            end
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
        database.drop_table(revision_table(revision)) if revision_exists?(revision)
      end

      def delete_all_revisions!
        database.tables.each do |table|
          database.drop_table(table) if revision_table?(table)
        end
      end

      def activate_dataset(dataset)
        # @@publishable_classes.each do |content_class|
        #   content_class.dataset = dataset unless content_class.dataset == dataset
        # end
      end

      def revision_pop
        @@revision, @@dataset = revision_stack.pop
      end

      def revision_stack
        @revision_stack ||= []
      end

      def revision_dataset(revision=nil)
        Spontaneous.database.dataset.from(revision_table(revision))
      end
    end

    module InstanceMethods
      def after_update
        super
        page.modified!(page?) if page
      end

      def modified!(caller_is_page)
        unless caller_is_page
          self.model.where(:id => self.id).update(:modified_at => Sequel.datetime_class.now)
        end
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
          published_copy = Spontaneous::Content[self.id]
          if published_copy
            if publish and published_copy.entry_store
              entries_to_delete = published_copy.entry_store - self.entry_store
              entries_to_delete.each do |entry|
                if c = Spontaneous::Content[entry[:id]]
                  c.destroy(false)
                end
              end
            end
          else # missing content (so force a publish)
            Spontaneous::Content.insert({:id => self.id})
            publish = true
          end

          if publish
            with_editable do
              self.entries.each do |entry|
                entry.target.sync_to_revision(revision, false)
              end
            end
            Spontaneous::Content.where(:id => self.id).update(self.values)
          end
        end
      end
    end
  end
end

