module Spontaneous
  module DataMapper
    class Scope

      def initialize(revision, visible, table, schema)
        @revision, @visible  = revision, visible
        @table, @schema      = table, schema
        @identity_map        = {}
      end

      def count(types = nil)
        dataset(types).count
      end

      # A type free version of #count
      def count!
        count(nil)
      end

      def filter(types, *cond, &block)
        dataset(types).filter(*cond, &block)
      end

      # A type free version of #filter
      def filter!(*cond, &block)
        filter(nil, *cond, &block)
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

      def delete(types)
        dataset(types).delete
      end

      def delete_instance(instance)
        dataset.delete_instance(instance)
      end

      def reload(instance)
        dataset.reload(instance)
      end

      def create(instance)
        dataset.create(instance)
      end

      def save(instance)
        dataset.save(instance)
      end

      def order(types, *columns, &block)
        dataset(types).order(*columns, &block)
      end

      def select(types, *columns, &block)
        dataset(types).select(*columns, &block)
      end

      def schema_uid(id_string)
        @schema.uids[id_string]
      end

      def columns
        @table.columns
      end

      def qualify_column(col)
        @table.qualify(@revision, col)
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

      def logger
        @table.logger
      end

      def logger=(logger)
        @table.logger = logger
      end

      def revision
        self
      end

      def visible_only?
        @visible || false
      end

      def dataset(types = nil)
        Dataset.new(table_dataset(types), @schema, @identity_map)
      end

      private

      def table_dataset(types)
        @table.dataset(@revision).filter(conditions(types))
      end

      def conditions(types)
        cond = type_conditions(types)
        cond[:hidden] = false if @visible
        cond
      end

      def type_conditions(types)
        return {} if types.nil?
        types = Array(types)
        return {} if types.empty?
        { :type_sid => types.flatten.map { |model| @schema.to_id(model) } }
      end
    end
  end
end
