module Spontaneous
  module DataMapper
    class Dataset
      include Enumerable

      def initialize(dataset, schema)
        @dataset, @schema = dataset, schema
      end

      def count
        @dataset.count
      end

      def get(id)
        first(id: id)
      end

      def first(*args, &block)
        load_instance @dataset.first(*args, &block)
      end

      def insert(*values, &block)
        @dataset.insert(*values, &block)
      end

      def save(instance)
        attributes = instance.modified_attributes
        id = instance.id
        return insert(instance) if id.nil?
        return instance if attributes.empty?
        @dataset.where(id: id).update(attributes)
        instance
      end

      def update(columns)
        @dataset.update(columns)
      end

      def create(instance)
        id = @dataset.insert(attributes_for_insert(instance))
        instance.set_attributes_after_save!(get_unfiltered_raw(id))
        instance
      end

      def delete
        @dataset.delete
      end

      def delete_instance(instance)
        @dataset.unfiltered.filter(id: instance.id).delete
      end

      def destroy
        @dataset.each do |row|
          load_instance(row).destroy
        end
      end

      def filter(*cond, &block)
        @dataset.filter!(*cond, &block)
        self
      end

      def where(*cond, &block)
        @dataset.where!(*cond, &block)
        self
      end

      def all
        load_instances @dataset.all
      end

      def reload(instance)
        attrs = get_raw(instance.id)
        instance.set_attributes!(attrs)
      end

      def and(*cond, &block)
        @dataset.and!(*cond, &block)
        self
      end

      def or(*cond, &block)
        @dataset.or!(*cond, &block)
        self
      end

      def each
        @dataset.each do |r|
          yield load_instance(r)
        end
      end

      def for_update
        @dataset.for_update!
        self
      end

      def order(*columns, &block)
        @dataset.order!(*columns, &block)
        self
      end

      def select(*columns, &block)
        @dataset.select!(*columns, &block)
        self
      end

      def qualify_to_first_source
        @dataset = @dataset.qualify_to_first_source
        self
      end

      def qualify(col)
        SQL::QualifiedIdentifier.new(table, k)
      end

      def to_sql
        @dataset.inspect
      end

      private

      def get_raw(id)
        @dataset.first(id: id)
      end

      def get_unfiltered_raw(id)
        @dataset.unfiltered.first(id: id)
      end

      def attributes_for_insert(instance)
        attributes_with_type_sid(instance.class, instance.attributes)
      end

      def attributes_with_type_sid(model, attributes)
        attributes = attributes.dup
        restricted = model.restricted_columns
        restricted.each { |col| attributes.delete(col)}
        attributes.update({
          type_sid: @schema.to_id(model)
        })
      end

      def load_instances(rows)
        rows.map { |row| load_instance(row) }
      end

      def load_instance(attributes)
        return nil if attributes.nil?
        return attributes if attributes[:type_sid].nil?
        model = @schema.to_class(attributes[:type_sid])
        allocate_instance(model, attributes)
      end

      def allocate_instance(model, attributes)
        instance = model.new(attributes, true)
        instance
      end
    end
  end
end
