module Spontaneous::Plugins
  module Fields
    module ClassMethods
      def field(name, type=:string, options={}, &block)
        if type.is_a?(Hash)
          options = type
          type = :string
        end

        local_field_order << name
        field_prototypes[name] = Spontaneous::FieldPrototype.new(name, type, options, &block)
        unless method_defined?(name)
          define_method(name) { fields[name] }
        else
          raise "Must give warning when field name clashes with method name"
        end

        setter = "#{name}=".to_sym
        unless method_defined?(setter)
          define_method(setter) { |value| fields[name].value = value  }
        else
          raise "Must give warning when field name clashes with method name"
        end
      end

      def field_prototypes
        @field_prototypes ||= {}
      end

      def field_names
        if @field_order && @field_order.length > 0
          remaining = default_field_order.reject { |n| @field_order.include?(n) }
          @field_order + remaining
        else
          default_field_order
        end
      end

      def default_field_order
        (supertype ? supertype.field_names : []) + local_field_order
      end

      def field_order(*new_order)
        @field_order = new_order
      end

      def local_field_order
        @local_field_order ||= []
      end

      def field?(field_name)
        field_name = field_name.to_sym
        field_prototypes.key?(field_name) || (supertype ? supertype.field?(field_name) : false)
      end

    end

    module InstanceMethods
      def after_initialize
        super
        if new?
          self.class.slots.instantiate(self)
        else
          self.class.slots.verify(self)
        end
      end
      def field_prototypes
        self.class.field_prototypes
      end

      def fields
        @field_set ||= Spontaneous::FieldSet.new(self, field_store)
      end

      def field?(field_name)
        self.class.field?(field_name)
      end

      # TODO: unify the update mechanism for these two stores
      def field_modified!(modified_field)
        self.field_store = @field_set.serialize
      end

    end
  end
end

