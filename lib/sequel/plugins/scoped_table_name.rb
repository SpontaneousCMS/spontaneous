# encoding: UTF-8

require 'active_support/core_ext/class/attribute'

module Sequel::Plugins
  # Provides models with a mechanism for changing the table name used by the model
  # within a particular block
  module ScopedTableName
    module DatasetClassMethods
      def table_mappings
        @table_mappings ||= {}
      end
    end

    module DatasetInstanceMethods
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
        self.class.table_mappings
      end
    end

    def self.configure(model)
      model.class_attribute :unscoped_table_name
      model.unscoped_table_name = model.dataset.opts[:from].first
      # apply the patch to the dataset class actually used by the model
      # as (e.g.) the MySQL adapter code overwrites #quote_identifier_append
      # so making the changes to Sequel::Dataset is pointless
      dataset_class = model.dataset.class
      unless dataset_class.method_defined?(:with_table)
        dataset_class.send :extend,  DatasetClassMethods
        dataset_class.send :include, DatasetInstanceMethods
      end
    end

    module ClassMethods
      def with_table(table_name, &block)
        dataset.with_table(unscoped_table_name, table_name, &block)
      end
    end
  end
end
