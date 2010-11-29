# encoding: UTF-8

# is this unforgivable?
# i think it's kinda neat, if a tad fragile (to columns named 'content'...)
module Sequel
  class Dataset
    alias_method :sequel_quote_identifier, :quote_identifier

    def quote_identifier(name)
      if name == "content"
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
        with_revision(Spontaneous::Site.published_revision, &block)
      end

      def revision_push(revision)
        revision_stack.push([@@revision, (@@dataset || self.dataset)])
        @@dataset = revision_dataset(revision)
        @@revision = revision
      end

      def database
        Spontaneous.database
      end

      def publish(revision, from_revision=nil, content=nil)
        if content.nil? or (content.is_a?(Array) and content.empty?)
          publish_all(revision, from_revision)
        else
          with_editable do
            content = content.map {|c| c.is_a?(Spontaneous::Content) ? c : Spontaneous::Content[c] }
          end
          if !from_revision.nil?
            create_revision(revision, from_revision)
            with_revision(revision) do
              content.each do |c|
                r = Spontaneous::Content[c.id]
                c.each_attribute do |k, v|
                  r[k] = v
                end
                r.save
              end
            end
          end
        end
      end

      def publish_all(revision, from_revision=nil)
        create_revision(revision, from_revision)
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
    end
  end
end

