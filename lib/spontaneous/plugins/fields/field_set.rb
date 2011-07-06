# encoding: UTF-8


module Spontaneous::Plugins
  module Fields
    class FieldSet < Spontaneous::PrototypeSet


      attr_reader :owner

      def initialize(owner, initial_values)
        super()
        @owner = owner
        initialize_from_prototypes(initial_values)
      end

      def initialize_from_prototypes(initial_values)
        values = Hash[(initial_values || []).map { |value| [Spontaneous::Schema::UID[value[:id]], value] }]
        owner.field_prototypes.each do |field_prototype|
          field = field_prototype.to_field(values[field_prototype.schema_id])
          add_field(field)
        end
      end

      # def [](name)
      #   store[name.to_sym]
      # end

      # def each
      #   owner.class.field_names.each do |name|
      #     yield(self[name])
      #   end
      # end

      # def find(id)
      #   self.values.detect { |f| f.schema_id == id }
      # end


      def serialize
        self.map { |field| field.serialize }
      end

      def to_hash
        owner.class.field_names.map do |name|
          self[name].to_hash
        end
      end

      def saved
        self.each { |field| field.mark_unmodified }
      end

      protected

      # def store
      #   @store
      # end

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
end
