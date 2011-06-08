# encoding: UTF-8

module Spontaneous::Plugins
  module Fields
    module ClassMethods
      def field(name, type=nil, options={}, &block)
        if type.is_a?(Hash)
          options = type
          type = nil
        end

        # if the field already exists then don't add it to our list
        # of local fields
        local_field_order << name unless field?(name)

        prototype = FieldPrototype.new(self, name, type, options, &block)
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

      # def supertype?
      #   supertype #&& supertype.respond_to?(:field_prototypes)
      # end

      def field_prototypes
        @field_prototypes ||= (supertype? ? superclass.field_prototypes.dup : {})
      end

      def field_names
        if @field_order && @field_order.length > 0
          remaining = default_field_order.reject { |n| @field_order.include?(n) }
          @field_order + remaining
        else
          default_field_order
        end
      end

      def fields
        field_names.map { |n| field_prototypes[n] }
      end

      def default_field_order
        (supertype? ? superclass.field_names : []) + local_field_order
      end

      def field_order(*new_order)
        @field_order = new_order
      end

      def local_field_order
        @local_field_order ||= []
      end

      def field?(field_name)
        field_name = field_name.to_sym
        field_prototypes.key?(field_name) || (supertype? ? superclass.field?(field_name) : false)
      end

      def field_for_mime_type(mime_type)
        fields.find do |prototype|
          prototype.field_class.accepts?(mime_type)
        end
      end

      def readable_fields
        field_names.select { |name| field_readable?(name) }
      end
    end

    module InstanceMethods
      def reload
        @field_set = nil
        super
      end

      def field_prototypes
        self.class.field_prototypes
      end

      def fields
        @field_set ||= FieldSet.new(self, field_store)
      end

      def field?(field_name)
        self.class.field?(field_name)
      end

      # TODO: unify the update mechanism for these two stores
      def field_modified!(modified_field)
        self.field_store = @field_set.serialize
      end

      def type_for_mime_type(mime_type)
        self.class.allowed_types.find do |t|
          t.instance_class.field_for_mime_type(mime_type)
        end.instance_class
      end

      def field_for_mime_type(mime_type)
        prototype = self.class.field_for_mime_type(mime_type)
        self.fields[prototype.name]
      end
    end
  end
end

