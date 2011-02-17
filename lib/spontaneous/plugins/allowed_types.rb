# encoding: UTF-8


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
        @options[:styles] = [@options[:style]] if @options.key?(:style)
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

      def prototype
        @options[:prototype]
      end

      def user_level
        level = @options[:level] || @options[:user_level] || Spontaneous::Permissions::UserLevel.minimum.to_sym
        Spontaneous::Permissions[level]
      end

      def readable?
        Spontaneous::Permissions.has_level?(user_level)
      end
    end

    module ClassMethods
      ##
      # Sets up an allowed type for a particular content type
      # this determines the list of types that appears in the editing UI
      #
      # Parameters:
      #   type  => A String, Symbol or Class defining the content type that is allowed
      #
      # Options:
      #
      #   :styles    => The list of (inline) style names that can be used by the entries
      #   :prototype => The name of the prototype to use when creating entries of this type
      #
      # TODO: finish these!
      def allow(type, options={})
        begin
          allowed_types_config << AllowedType.new(type, options)
        rescue NameError => e
          raise Spontaneous::UnknownTypeException.new(self, type)
        end
      end

      def allowed_types_config
        @_allowed_types ||= []
      end

      def allowed
        (supertype ? supertype.allowed : []).concat(allowed_types_config)
      end
      alias_method :allowed_types, :allowed
    end

    module InstanceMethods
      def allowed_types
        self.class.allowed_types
      end

      def allowed_type(content)
        self.class.allowed.find { |a| a.instance_class == content.class }
      end

      def prototype_for_content(content, box = nil)
        if allowed = allowed_type(content)
          allowed.prototype
        else
          nil
        end
      end

      # TODO: BOXES remove box reference here
      def style_for_content(content, box = nil)
        if allowed = allowed_type(content)
          allowed.default_style
        else
          content.styles.default
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

