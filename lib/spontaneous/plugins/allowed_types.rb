# encoding: UTF-8


module Spontaneous::Plugins
  module AllowedTypes
    class AllowedType
      attr_accessor :allow_subclasses

      def initialize(type, options={})
        @type = type
        @options = options
        # check_instance_class
        # check_styles
      end

      def check_instance_class
        instance_class
      end

      def check_styles
        @options[:styles] = [@options[:style]] if @options.key?(:style)
        if @options.key?(:styles) and styles = @options[:styles]
          styles.each do |s|
            if instance_class.find_named_style(s).nil?
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
          # begin
          @type.to_s.constantize
          # rescue  => e
          #   p self
          # end
        end
      end

      def styles
        configured_styles || all_styles
      end

      def configured_styles
        if (@options.key?(:styles) and styles = @options[:styles]) or \
          (@options.key?(:style) and styles = [@options[:style]].flatten)
          styles.map { |s| instance_class.find_named_style(s) }
        end
      end

      def includes?(type)
        if allow_subclasses
          instance_class.subclasses.include?(type)
        else
          instance_class == type
        end
      end

      def instance_classes
        if allow_subclasses
          instance_class.subclasses
        else
          [instance_class]
        end
      end

      def all_styles
        instance_class.styles
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

      def readable?(user)
        Spontaneous::Permissions.has_level?(user, user_level)
      end
      alias_method :addable?, :readable?
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
      #   :styles    => The list of (inline) style names that can be used by the pieces
      #   :prototype => The name of the prototype to use when creating pieces of this type
      #
      # TODO: finish these!
      def allow(type, options={})
        allowed_types_config << AllowedType.new(type, options)
      end

      # TODO: implement this in a way that doesn't require searching through constants at load-time
      def allow_subclasses(type, options = {})
        parent_type = AllowedType.new(type)
        parent_type.allow_subclasses = true
        allowed_types_config << parent_type
        # parent_type.instance_class.subclasses.each do |subclass|
        #   allow(subclass, options)
        # end
      end

      def allowed_types_config
        @_allowed_types ||= []
      end

      def allowed
        (supertype ? supertype.allowed : []).concat(allowed_types_config)
      end
      def allowed_types
        types = []
        allowed.each { |a| types.concat(a.instance_classes) }
        types
      end
    end

    module InstanceMethods
      def allowed
        self.class.allowed
      end

      def allowed_types
        self.class.allowed_types
      end

      def allowed_type(content)
        klass = content.is_a?(Class) ? content : content.class
        self.class.allowed.find { |a| a.includes?(klass) }
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
          content.default_style
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

