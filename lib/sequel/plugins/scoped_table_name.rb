# encoding: UTF-8

# module Sequel
#   class Dataset
#     alias_method :sequel_quote_identifier_append, :quote_identifier_append
#
#     def quote_identifier_append(sql, name)
#       if name == :content or name == "content"
#         name = Spontaneous::Content.current_revision_table
#       end
#       sequel_quote_identifier_append(sql, name)
#       # super(sql, name)
#     end
#   end
# end
module Sequel::Plugins
  module DatasetTableScoping
    module ClassMethods
      def with_table(table_name)
        restore = self.dataset
        @dataset = self.dataset.from(SQLTableName.new(table_name))
        yield if block_given?
      ensure
        @dataset = restore
      end
    end
    def quote_identifier_append(sql, name)
      # if name == :content or name == "content"
      # name = Spontaneous::Content.current_revision_table
      name = ScopedTableName.scoped_identifier(name)
      # end
      sequel_quote_identifier_append(sql, name)
      # super(sql, name)
    end
  end

  module ScopedTableName

    @@table_name = nil

    def current_table_name
      @@table_name
    end


    def self.configure(*args)
      # Sequel::Dataset.send(:alias_method, :sequel_quote_identifier_append, :quote_identifier_append)
      # Sequel::Dataset.send(:include, DatasetTableScoping)
      Sequel::Dataset.plugin :dataset_table_scoping
    end

    module ClassMethods
      # class SQLTableName
      #   def initialize(table_name)
      #     @table_name = table_name
      #   end
      #   def sql_literal(ds)
      #     "`#{@table_name}`"
      #   end
      #   def to_s
      #     @table_name
      #   end
      # end

      def with_table(table_name)
        restore = self.dataset
        @dataset = self.dataset.from(SQLTableName.new(table_name))
        yield if block_given?
      ensure
        @dataset = restore
      end
    end
  end
end
