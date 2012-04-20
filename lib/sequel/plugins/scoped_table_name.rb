# encoding: UTF-8

module Sequel::Plugins
  # Provides models with a mechanism for changing the table name used by queries
  # within a particular block
  module ScopedTableName
    def self.configure(model)
      model.class_variable_set :"@@unscoped_table_name", model.dataset.opts[:from].first
    end

    module ClassMethods
      def unscoped_table_name
        class_variable_get :"@@unscoped_table_name"
      end

      def fast_instance_delete_sql
        nil
      end

      def primary_key_lookup(pk)
        dataset[primary_key_hash(pk)]
      end

      def with_table(table_name, &block)
        @dataset.with_table(unscoped_table_name, table_name, &block)
      end
    end

    module DatasetMethods
      # set up a mapping from the datasets original name to the one that should be used
      # in the current scope.
      # called from the model class this
      def with_table(original_table_name, current_table_name)
        saved_table_name = table_mappings[original_table_name]
        table_mappings[original_table_name] = current_table_name.to_s

        yield if block_given?
      ensure
        table_mappings[original_table_name] = saved_table_name
      end

      # use the table_mappings to convert the original table name to the current version
      def quote_identifier_append(sql, name)
        name = (table_mappings[name.to_sym] || name) if name.respond_to?(:to_sym)
        super(sql, name)
      end

      # the table name mappings are shared across all dataset instances
      def table_mappings
        Thread.current[:scoped_table_names] ||= {}
      end
    end
  end
end
