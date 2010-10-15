
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

      def extended_class(klass)
        if @extend
          klass = Class.new(klass)
          klass.class_eval(&@extend)
        end
        klass
      end

      def anonymous_class
        @anonymous_class ||= Class.new(Spontaneous::Facet).tap do |klass|
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
          instance_class.name
        end
      end
    end
  end
end

