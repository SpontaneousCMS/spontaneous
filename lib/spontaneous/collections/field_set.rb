# encoding: UTF-8

module Spontaneous::Collections
  class FieldSet < PrototypeSet

    attr_reader :owner

    def initialize(owner, initial_values)
      super()
      @owner = owner
      initialize_from_prototypes(initial_values)
    end

    def initialize_from_prototypes(initial_values)
      values = (initial_values || []).map do |value|
        value = S::FieldTypes.deserialize_field(value)
        [Spontaneous::Schema::UID[value[:id]], value]
      end
      values = Hash[values]
      owner.field_prototypes.each do |field_prototype|
        field = field_prototype.to_field(values[field_prototype.schema_id])
        add_field(field)
      end
    end

    def serialize_db
      self.map { |field| field.serialize_db }
    end

    def export
      owner.class.field_names.map do |name|
        self[name].export
      end
    end

    def saved
      self.each { |field| field.mark_unmodified }
    end

    protected

    def add_field(field)
      field.owner = owner
      getter_name = field.name
      setter_name = "#{field.name}="
      self[field.name.to_sym] = field
      singleton_class.class_eval do
        define_method(getter_name) { |*args| field.tap { |f| f.template_params = args } }
        define_method(setter_name) { |value| field.value = value }
      end
    end
  end
end
