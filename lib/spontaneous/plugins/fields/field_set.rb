
module Spontaneous::Plugins
  module Fields
    class FieldSet

      def initialize(owner, initial_values)
        @owner = owner
        @store = Hash.new
        initialize_from_prototypes(initial_values)
      end

      def initialize_from_prototypes(initial_values)
        values = (initial_values || []).inject({}) do |hash, value|
          hash[value[:name].to_sym] = value; hash
        end
        prototype_names = []
        owner.field_prototypes.each do |field_name, field_prototype|
          # use this to look for orphaned fields in initial_values
          prototype_names << field_name
          field = field_prototype.to_field(values[field_name])
          add_field(field)
        end
      end

      def [](name)
        store[name.to_sym]
      end

      def owner
        @owner
      end

      def serialize
        store.map { |name, field| field.serialize }
      end

      protected

      def store
        @store
      end

      def add_field(field)
        field.owner = owner
        getter_name = field.name
        setter_name = "#{field.name}="
        store[getter_name.to_sym] = field
        meta.class_eval do
          define_method(getter_name) { field }
          define_method(setter_name) { |value| field.value = value }
        end
        # owner.meta.class_eval do
        #   define_method(getter_name) { field }
        #   define_method(setter_name) { |value| field.value = value }
        # end
      end

      def meta
        @_meta ||= \
          class << self; self; end
      end

    end
  end
end
