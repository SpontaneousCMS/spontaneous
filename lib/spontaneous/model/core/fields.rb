# encoding: UTF-8

module Spontaneous::Model::Core
  module Fields
    extend Spontaneous::Concern

    module ClassMethods
      def field(name, type=nil, options={}, &block)
        if type.is_a?(Hash)
          options = type
          type = nil
        end
        prototype = nil
        name = name.to_sym

        # Because of load conflicts types are likely to be loaded twice
        return self.fields[name] if self.field?(name, false)

        if (existing_prototype = field_prototypes[name])
          prototype = existing_prototype.merge(self, type, options, &block)
        else
          prototype = Spontaneous::Prototypes::FieldPrototype.new(self, name, type, options, &block)
        end

        field_prototypes[name] = prototype
        unless method_defined?(name)
          define_method(name) do |*args|
            fields[name].tap { |f| f.template_params = args }
          end
        else
          # raise "Must give warning when field name clashes with method name #{name}"
        end

        setter = "#{name}=".to_sym
        unless method_defined?(setter)
          define_method(setter) { |value| fields[name].value = value  }
        else
          # raise "Must give warning when field name clashes with method name"
        end
        prototype
      end

      def field_prototypes
        @field_prototypes ||= Spontaneous::Collections::PrototypeSet.new(supertype, :field_prototypes)
      end

      def field_names
        field_prototypes.order
      end

      def fields
        field_prototypes
      end

      def field_order(*new_order)
        field_prototypes.order = new_order.flatten if new_order and !new_order.empty?
      end

      def field?(field_name, inherited = true)
        field_prototypes.key?(field_name, inherited)
      end

      def field_for_mime_type(mime_type)
        fields.find do |prototype|
          prototype.field_class.accepts?(mime_type)
        end
      end

      def readable_fields
        field_prototypes.keys.select { |name| field_readable?(name) }
      end
    end # ClassMethods

    # InstanceMethods

    def before_create
      serialize_fields(fields.with_dynamic_default_values)
      super
    end

    def after_save
      super
      fields.saved
    end

    def before_save
      save_field_versions unless new?
      super
    end

    def field_versions(field)
      Spontaneous::Field::FieldVersion.filter(:content_id => self.id, :field_sid => field.schema_id.to_s).order(Sequel.desc(:created_at))
    end

    def save_field_versions
      fields.each do |field|
        field.create_version if field.modified?
      end
    end

    def reload
      @field_set = nil
      super
    end

    def field_prototypes
      self.class.field_prototypes
    end

    def fields
      @field_set ||= Spontaneous::Collections::FieldSet.new(self, field_store)
    end

    # Used by #content_hash to attempt to preserve content hashes across
    # schema changes
    def fields_with_consistent_order
      fields.sort { |f1, f2| f1.schema_id <=> f2.schema_id }
    end

    def field?(field_name)
      self.class.field?(field_name)
    end

    # TODO: unify the update mechanism for these two stores
    def field_modified!(modified_field = nil)
      serialize_fields
    end

    def serialize_fields(fields = nil)
      self.field_store = update_serialized_fields(fields)
    end

    def update_serialized_fields(fields = nil)
      if fields.nil?
        @field_set.serialize_db
      else
        field_store = (self.field_store || []).dup
        fields.each do |field|
          before_save_field(field)
          schema_id = field.schema_id.to_s
          if (index = field_store.index { |f| f[0] == schema_id })
            field_store[index.to_i] = field.serialize_db
          else
            field_store << field.serialize_db
          end
        end
        field_store
      end
    end

    def before_save_field(field)
    end

    # Re-serializes the field store.
    #
    # If fields is given then only the fields included in it will be written
    def save_fields(fields = nil)
      serialize_fields(fields)
      save
    end

    def type_for_mime_type(mime_type)
      self.class.allowed_types.find do |t|
        t.field_for_mime_type(mime_type)
      end
    end

    def field_for_mime_type(mime_type)
      prototype = self.class.field_for_mime_type(mime_type)
      self.fields[prototype.name]
    end
  end
end
