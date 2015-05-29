require 'spontaneous/data_mapper/content_model/column_accessors'
require 'spontaneous/data_mapper/content_model/serialization'
require 'spontaneous/data_mapper/content_model/timestamps'
require 'spontaneous/data_mapper/content_model/instance_hooks'
require 'spontaneous/data_mapper/content_model/associations'

module Spontaneous
  module DataMapper
    module ContentModel
      def self.extended(model)
        model.send :include, InstanceMethods
      end

      def self.generate(mapper, &block)
        Class.new do
          extend Spontaneous::DataMapper::ContentModel
          class_eval &block if block
          self.mapper = mapper
          include ColumnAccessors
          include Serialization
          include Timestamps
          include InstanceHooks
          include Associations::InstanceMethods
        end
      end

      attr_reader :mapper
      attr_writer :options

      def inherited(subclass)
        @mapper.inherited(self, subclass)
        subclass.mapper  = @mapper
        super
      end

      def mapper=(mapper)
        @mapper = mapper
      end

      def restricted_columns
        [:id, :type_sid]
      end

      def serialize_columns(*columns)
        define_singleton_method(:serialized_columns) { columns }
      end

      def serialized_columns
        []
      end

      def include_all_types
        include_types()
      end

      def include_types(*types, &block)
        if block_given?
          define_singleton_method(:types, &block)
        else
          define_singleton_method(:types) { types }
        end
      end

      def types
        [self]
      end

      def subclasses
        mapper.subclasses(self)
      end

      def columns
        @columns ||= mapper.columns - restricted_columns
      end

      def db
        mapper.db
      end

      def schema
        mapper.schema
      end

      def get(id)
        mapper.get(id)
      end

      # Allows for Page/123 => #<Page id=123...>
      alias_method :/, :get
      alias_method :[], :get

      def primary_key_lookup(id)
        mapper.primary_key_lookup(id)
      end

      def count
        mapper.count(types)
      end

      def dataset
        mapper.dataset(types)
      end

      # Allow for iterating over all instances of a type using:
      #
      #    Type.each { |instance| ... }
      #
      def each(&block)
        dataset.each(&block)
      end

      # Allow for mapping all instances of a type using:
      #
      #    Type.map { |instance| ... }
      #
      def map(&block)
        dataset.map(&block)
      end

      def all
        mapper.all(*types)
      end

      def all!(&block)
        mapper.all!(&block)
      end

      def first(*args, &block)
        mapper.first(types, *args, &block)
      end

      def first!(*args, &block)
        mapper.first!(*args, &block)
      end

      def filter(*cond, &block)
        mapper.filter(types, *cond, &block)
      end

      def filter!(*cond, &block)
        mapper.filter!(*cond, &block)
      end

      def exclude(*cond, &block)
        mapper.exclude(types, *cond, &block)
      end

      def exclude!(*cond, &block)
        mapper.exclude!(*cond, &block)
      end

      def where(*cond, &block)
        mapper.where(types, *cond, &block)
      end

      def where!(*cond, &block)
        mapper.where!(*cond, &block)
      end

      def create(attrs = {})
        self.new(attrs).save
      end

      def insert(attrs = {})
        mapper.insert(attrs)
      end

      def update(attrs)
        mapper.update(types, attrs)
      end

      def delete(&block)
        mapper.delete(types, &block)
      end

      def order(*columns, &block)
        mapper.order(types, *columns, &block)
      end

      def limit(l, o = (no_offset = true; nil))
        mapper.limit(types, l, o)
      end

      def for_update
        mapper.for_update
      end

      def select(*columns, &block)
        mapper.select(types, *columns, &block)
      end

      def visible
        mapper.visible.dataset(types)
      end

      def columns
        mapper.columns
      end

      def primary_key
        mapper.primary_key
      end

      def table_name
        mapper.table_name
      end

      include Associations

      module InstanceMethods

        HOOKS = [ :create, :save, :update, :destroy ] unless defined?(HOOKS)

        HOOKS.each do |hook|
          module_eval "def before_#{hook}; end", __FILE__, __LINE__
          module_eval "def after_#{hook} ; end", __FILE__, __LINE__
        end

        def initialize(attr = {}, from_db = false)
          @modified = false
          if from_db
            @new = false
            set_attributes!(attr)
          else
            @new = true
            @modified = true
            @attributes = {}
            changed_columns.clear
            set(attr)
          end
          trigger_hook(:after_initialize)
        end

        def after_initialize; end

        def attributes
          @attributes.dup
        end

        def mapper
          model.mapper
        end

        def save
          id = nil
          saved = false
          trigger_hook(:before_save) do
            if new?
              trigger_hook(:before_create) do
                mapper.create(self)
                @new  = false
                saved = true
                trigger_hook(:after_create)
                self
              end
            else
              trigger_hook(:before_update) do
                mapper.save(self)
                saved = true
                changed_columns.clear
                trigger_hook(:after_update)
                self
              end
            end
            return nil unless saved
            trigger_hook(:after_save)
          end
          @modified = false
          self
        end

        def trigger_hook(callback)
          catch :halt do
            send(callback)
            return yield if block_given?
            return self
          end
          nil
        end

        def mark_modified!(*columns)
          if columns.empty?
            @modified = true
          else
            _mark_columns_as_modified(*columns)
          end
        end

        def modified?
          @modified || !changed_columns.empty?
        end

        def reload
          refresh
        end

        def _after_save_refresh
          refresh
        end

        def refresh
          changed_columns.clear
          mapper.reload(self)
          self
        end

        def destroy
          deleted = false
          trigger_hook(:before_destroy) do
            delete
            deleted = true
            trigger_hook(:after_destroy)
            self
          end
          return nil unless deleted
          self
        end

        def delete
          mapper.delete_instance(self)
        end

        def new?
          @new
        end

        def id
          @attributes[:id]
        end

        alias_method :pk, :id

        def update(values)
          set(values)
          save
        end

        def set(values)
          set_restricted(values)
        end

        def model
          self.class
        end

        def set_restricted(attrs)
          exclude = model.restricted_columns
          attrs.each do |column, value|
            send("#{column}=", value) unless exclude.include?(column.to_sym)
          end
        end

        def set_attributes!(attributes)
          @attributes = attributes
        end

        def set_attributes_after_save!(attributes)
          set_attributes!(attributes)
          changed_columns.clear
          @new = false
        end

        def ==(obj)
          eql?(obj)
        end

        def eql?(obj)
          return false if obj.nil?
          # p [:eql?]
          # p obj
          # @attributes.each do |k, v|
          #   p [k, v == obj.attributes[k]]
          # end
          (obj.class == model) && (obj.attributes == @attributes)
        end

        def hash
          [model, id.nil? ? (@values || {}).sort_by{|k,v| k.to_s} : id].hash
        end
      end
    end
  end
end
