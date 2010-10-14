
module Spontaneous::Plugins
  module AllowedTypes
    class AllowedType
      def initialize(type, options={})
        @type = type
        @options = options
        check_instance_class
        check_styles
      end

      def check_instance_class
        instance_class
      end

      def check_styles
        if @options.key?(:styles) and styles = @options[:styles]
          styles.each do |s|
            if instance_class.inline_styles[s].nil?
              raise Spontaneous::UnknownStyleException.new(s, instance_class)
            end
          end
        end
      end

      def instance_class
        case @type
        when Class
          @type
        when Symbol, String
          @type.to_s.constantize
        end
      end

      def styles
        configured_styles || all_styles
      end

      def configured_styles
        if @options.key?(:styles) and styles = @options[:styles]
          styles.map { |s| instance_class.inline_styles[s] }
        end
      end

      def all_styles
        instance_class.inline_styles
      end

      def default_style
        styles.first
      end
    end

    module ClassMethods
      def allow(type, options={})
        begin
          allowed_types << AllowedType.new(type, options)
        rescue NameError => e
          raise Spontaneous::UnknownTypeException.new(self, type)
        end
      end

      def allowed_types
        @allowed_types ||= []
      end

      def allowed
        allowed_types
      end
    end

    module InstanceMethods
      def allowed_type(content)
        self.class.allowed.find { |a| a.instance_class == content.class }
      end

      def style_for_content(content)
        if allowed = allowed_type(content)
          allowed.default_style
        else
          super
        end
      end

      def available_styles(content)
        if allowed = allowed_type(content)
          allowed.styles
        else
          super
        end
      end
    end
  end
end

