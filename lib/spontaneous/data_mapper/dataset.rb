module Spontaneous
  module DataMapper
    class Dataset
      include Enumerable

      def initialize(dataset, schema, identity_map)
        @dataset, @schema, @identity_map = dataset, schema, identity_map
      end

      def count
        @dataset.count
      end

      def get(id)
        return get_all(id) if id.is_a?(Array)
        if (instance = @identity_map[id])
          instance
        else
          primary_key_lookup(id)
        end
      end

      # Gets all the instances for the list of ids and returns them
      # in the id order of the list, rather than the db order.
      def get_all(id_list)
        # This pure-db solution is Postgresql only unfortunately...
        #
        # values = []
        # id_list.each_with_index do |id, index|
        #   values << ("(" << [id, index].join(",") << ")")
        # end
        # ds = @dataset.filter(:id => id_list).qualify.
        # join(Sequel::LiteralString.new("(VALUES #{values.join(",")}) AS id_order (id, pos)"), {:id_order__id => :id}, {:qualify => true}).
        # order(:id_order__pos)
        order = Hash[id_list.each_with_index.map { |id, index| [id, index] }]
        filter(:id => id_list).all.sort { |i1, i2|
          order[i1.id] <=> order[i2.id]
        }
      end

      def primary_key_lookup(pk)
        first(id: pk)
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

      def exclude(*cond, &block)
        @dataset.exclude!(*cond, &block)
        self
      end

      def where(*cond, &block)
        @dataset.where!(*cond, &block)
        self
      end

      def map(column = nil, &block)
        if column
          @dataset.map(column)
        else
          super(&block)
        end
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
        return enum_for(:each) unless block_given?
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

      def limit(l, o = (_no_offset = true; nil))
        @dataset.limit!(l, o)
        self
      end

      def offset(o)
        @dataset.offset!(o)
        self
      end

      def select(*columns, &block)
        @dataset.select!(*columns, &block)
        self
      end

      def invert
        @dataset.invert!
        self
      end

      class PreparedStatement
        def initialize(name, ds, ps)
          @name = name
          @ds = ds
          @ps = ps
        end

        def call(vars = {})
          results = @ps.call(vars)
          case results
          when Array
            @ds.load_instances(results)
          else
            @ds.load_instance(results)
          end
        end
      end

      def prepare(type, name, *values)
        ps = @dataset.prepare(type, name, *values)
        PreparedStatement.new(name, self, ps)
      end

      def db
        @dataset.db
      end

      def qualify_to_first_source
        @dataset = @dataset.qualify_to_first_source
        self
      end

      def qualify(col)
        SQL::QualifiedIdentifier.new(table, k)
      end

      def to_sql
        @dataset.sql
      end

      def unfiltered
        @dataset.unfiltered
      end

      def ds
        @dataset
      end

      alias_method :sql, :to_sql

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
        allocate_instance(attributes)
      end

      def allocate_instance(attributes)
        return attributes if attributes[:type_sid].nil?
        if (instance = @identity_map[attributes[:id]])
          instance
        else
          model = @schema.to_class(attributes[:type_sid])
          return nil if model.nil?
          instance = model.new(attributes, true)
          @identity_map[instance.id] = instance
        end
      end

      def inspect
        %(#<Spontaneous::DataMapper::Dataset:#{object_id.to_s(16)} dataset=#{@dataset.sql}>)
      end
    end
  end
end
