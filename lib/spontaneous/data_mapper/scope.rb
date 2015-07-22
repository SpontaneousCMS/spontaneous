module Spontaneous
  module DataMapper
    class Scope

      def initialize(dataset, schema)
        @dataset      = dataset
        @schema       = schema
        @identity_map = {}
        @schema_types = @schema.types
      end

      def count(types = nil)
        dataset(types).count
      end

      # A type free version of #count
      def count!
        count(nil)
      end

      def untyped
        untyped_dataset
      end

      def filter(types, *cond, &block)
        dataset(types).filter(*cond, &block)
      end

      # A type free version of #filter
      def filter!(*cond, &block)
        filter(nil, *cond, &block)
      end

      def exclude(types, *cond, &block)
        dataset(types).exclude(*cond, &block)
      end

      # A type free version of #filter
      def exclude!(*cond, &block)
        exclude(nil, *cond, &block)
      end

      def where(types, *cond, &block)
        dataset(types).where(*cond, &block)
      end

      # A type free version of #where
      def where!(*cond, &block)
        where(nil, *cond, &block)
      end

      def first(types, *args, &block)
        dataset(types).first(*args, &block)
      end

      # A type free version of #first
      def first!(*args, &block)
        first(nil, *args, &block)
      end

      def all(*types, &block)
        instances = dataset(types).all
        instances.each(&block) if block_given?
        instances
      end

      # A type free version of #all
      def all!(&block)
        all(nil, &block)
      end

      # Get doesn't need typing as it retrieves a single instance by direct
      # id reference.
      def get(id)
        dataset.get(id)
      end

      def primary_key_lookup(id)
        dataset.primary_key_lookup(id)
      end

      alias_method :[], :get

      def insert(*values, &block)
        dataset.insert(*values, &block)
      end

      def instance(model, attributes)
        model.create(attributes)
      end

      def update(types, columns)
        dataset(types).update(columns)
      end

      # A type free version of #update
      def update!(columns)
        update(nil, columns)
      end

      def for_update
        dataset.for_update
      end

      def delete(types = nil)
        dataset(types, {}).delete
      end

      def delete_instance(instance)
        dataset.delete_instance(instance)
      end

      def reload(instance)
        untyped_dataset.reload(instance)
      end

      def create(instance)
        dataset.create(instance)
      end

      def save(instance)
        untyped_dataset.save(instance)
      end

      def order(types, *columns, &block)
        dataset(types).order(*columns, &block)
      end

      def limit(types, l, o = (no_offset = true; nil))
        dataset(types).limit(l, o)
      end

      def select(types, *columns, &block)
        dataset(types).select(*columns, &block)
      end

      def prepare(type, name, *values, &block)
        prepared_statements[name] ||= begin
          ds = block.call
          ds.prepare(type, name, *values)
        end
      end

      def prepared_statements
        @prepared_statements ||= {}
      end

      def schema_uid(id_string)
        @schema.uids[id_string]
      end

      def columns
        @dataset.columns
      end

      def qualify_column(col)
        Sequel::SQL::QualifiedIdentifier.new(@dataset.first_source, col)
      end

      def each(&block)
        dataset.each(&block)
      end

      def with_cache(key, &block)
        if @identity_map.key?(key)
          @identity_map[key]
        else
          @identity_map[key] = block.call
        end
      end

      def clear_cache(key)
        @identity_map.delete(key)
      end

      def pk
        @dataset.db.primary_key(@dataset.first_source).to_sym
      end

      def table_name
        naked_dataset.first_source_table
      end

      def logger
        @dataset.logger
      end

      def logger=(logger)
        @dataset.db.logger = logger
      end

      def revision
        self
      end

      def dataset(types = nil, fallback_type_condition = all_types_condition)
        Dataset.new(table_dataset(types, fallback_type_condition), @schema, @identity_map)
      end

      def untyped_dataset
        Dataset.new(naked_dataset, @schema, @identity_map)
      end

      private

      def table_dataset(types, fallback_type_condition)
        conditions = conditions(types, fallback_type_condition)
        return naked_dataset.filter(conditions)
        ds = nil
        unless (ds = cached_datasets[conditions])
          cached_datasets[conditions] = ds = naked_dataset.filter(conditions)
        end
        ds
      end

      def cached_datasets
        @cached_datasets ||= {}
      end

      def naked_dataset
        @dataset.dup
      end

      def conditions(types, fallback_type_condition)
        type_conditions(types, fallback_type_condition)
      end

      def type_conditions(types, fallback_type_condition)
        types = Array(types)
        return fallback_type_condition if types.empty?
        { :type_sid => types.flatten.map { |model| @schema.to_id(model) } }
      end

      def all_types_condition
        type_condition(@schema_types)
      end

      def type_condition(types)
        { :type_sid => types.flatten.map { |model| @schema.to_id(model) } }
      end
    end
  end
end
