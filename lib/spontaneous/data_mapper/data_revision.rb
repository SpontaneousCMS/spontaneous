module Spontaneous
  module DataMapper
    class DataRevision

      def initialize(revision, visibility, table, schema)
        @revision   = revision
        @visibility = visibility
        @table, @schema = table, schema
        @identity_map = {}
      end

      def count(models = nil)
        dataset.filter(type_filter(models)).count
      end

      def count!
        count(nil)
      end

      def filter(models, *cond, &block)
        dataset.filter(type_filter(models)).filter(*cond, &block)
      end

      def filter!(*cond, &block)
        filter(nil, *cond, &block)
      end

      def where(models, *cond, &block)
        dataset.where(type_filter(models)).where(*cond, &block)
      end

      def where!(*cond, &block)
        where(nil, *cond, &block)
      end

      def first(models, *args, &block)
        dataset.filter(type_filter(models)).first(*args, &block)
      end

      def first!(*args, &block)
        first(nil, *args, &block)
      end

      def all(*models, &block)
        instances = typed_dataset(models).all
        instances.each(&block) if block_given?
        instances
      end

      def all!(&block)
        all(nil, &block)
      end

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

      def update(models, columns)
        typed_dataset(models).update(columns)
      end

      def update!(columns)
        update(nil, columns)
      end

      def for_update
        dataset.for_update
      end

      def delete(models)
        typed_dataset(models).delete
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

      def order(models, *columns, &block)
        typed_dataset(models).order(*columns, &block)
      end

      def select(models, *columns, &block)
        typed_dataset(models).select(*columns, &block)
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
        @visibility || false
      end

      def dataset(models = nil)
        ds = Dataset.new(raw_dataset(@revision), @schema, @identity_map)
        return typed_dataset(models, ds) unless models.nil?
        ds
      end

      def typed_dataset(models, ds = dataset)
        ds.filter(type_filter(models))
      end

      alias_method :typed, :typed_dataset

      def type_filter(models, existing_filter = {})
        return existing_filter if models.nil?
        filter = {}.update(existing_filter)
        sids = Array(models || []).flatten.map { |model| @schema.to_id(model)}
        filter[:type_sid] = sids unless sids.empty?
        filter
      end

      def raw_dataset(revision_number)
        @table.dataset(revision_number).tap do |ds|
          ds.filter!(hidden: !@visibility) if @visibility
        end
      end
    end
  end
end
