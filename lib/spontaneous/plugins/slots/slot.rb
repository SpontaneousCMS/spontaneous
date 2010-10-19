
module Spontaneous::Plugins
  module Slots
    class Slot
      attr_reader :name

      def initialize(owning_class, name, options={}, &block)
        @owning_class = owning_class
        @name = name.to_sym
        @options = options
        @extend = block
      end

      def title
        @options[:title] || default_title
      end

      def tag
        @options[:tag]
      end

      def default_title
        name.to_s.titleize
      end

      def style
        @options[:style]# || name
      end

      def instance_class
        @instance_class ||= \
          case klass = @options[:class]
          when Class
            extended_class(klass)
          when String, Symbol
            extended_class(klass.to_s.constantize)
          else
            anonymous_class
          end
      end

      def anonymous?
        @options[:class].nil?
      end

      def extended_class(extend_klass)
        define_slot_class(extend_klass).tap do |klass|
          klass.class_eval(&@extend) if @extend
        end
      end

      def define_slot_class(superclass)
        Object.class_eval "class #{slot_class_name} < #{superclass.name}; end"
        Object.const_get(slot_class_name)
      end

      def slot_class_name
        "#{owning_class_name}__#{name.to_s.camelize}Slot"
      end

      def owning_class_name
        name = @owning_class.name
        if name.nil? or name.empty?
          "Content"
        else
          name
        end
      end

      def anonymous_class
        @anonymous_class ||= define_slot_class(Spontaneous::Facet).tap do |klass|
          klass.class_eval(&@extend) if @extend
          if style
            klass.inline_style style, :class_name => template_class_name
          end
        end
      end

      def template_class_name
        if anonymous?
          @owning_class.name
        else
          instance_class.superclass.name
        end
      end
    end
  end
end

