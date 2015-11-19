# encoding: UTF-8

module Spontaneous::Model::Box
  module AllowedTypes
    extend Spontaneous::Concern

    class AllowedType
      prepend Spontaneous::Model::Page::Singleton::AllowedTypeMethods

      attr_accessor :allow_subclasses

      def initialize(box, type, options={}, &definition)
        @box_class  = box
        @type       = type
        @options    = options
        define_instance_class(definition) if definition
      end

      def schema
        @box_class.mapper.schema
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
        resolve_instance_class(@type)
      end

      def define_instance_class(definition)
        content_type = Class.new(instance_class_supertype, &definition)
        @box_class.const_set @type, content_type
        @type = content_type.name
      end

      def instance_class_supertype
        type = @options[:supertype] || (defined?(::Piece) ? ::Piece : Content::Piece)
        constantize type
      end

      def styles(content)
        configured_styles(content) || all_styles(content)
      end

      def configured_styles(content)
        if (styles = style_options)
          styles.map { |s| instance_class.find_named_style(s) }
        end
      end

      def all_styles(content)
        instance_class.styles
      end

      def default_style(content)
        styles(content).first
      end

      def style_options
        return Array(@options[:styles]) if @options.key?(:styles)
        return Array(@options[:style])  if @options.key?(:style)
        nil
      end

      def includes?(type)
        if allow_subclasses
          instance_class.subclasses.include?(type)
        else
          instance_class == type
        end
      end

      def instance_classes
        unfiltered_instance_classes.reject {|type| exclude_type?(type) }
      end

      def unfiltered_instance_classes
        if allow_subclasses
          instance_class.subclasses
        else
          [instance_class]
        end
      end

      def exclude_type?(type)
        false
      end

      def export
        if allow_subclasses
          # can't configure interface name using allow_subclasses
          instance_class.subclasses.map { |c| { type: c.ui_class } }
        else
          instance_classes.map {|instance_class|
            exported = {type: instance_class.ui_class }
            exported[:as] = @options[:as] if @options.key?(:as)
            exported
          }
        end
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

      protected

      def resolve_instance_class(name)
        constantize(name)
      end

      def constantize(name)
        case name
        when Class
          name
        when Symbol, String
          name.to_s.constantize
        end
      end

    end

    class AllowedGroup < AllowedType
      def groups
        @type
      end

      def unfiltered_instance_classes
        names = groups.flat_map { |name| schema.groups[name] }
        names.map { |name| resolve_instance_class(name) }.uniq
      end

      def includes?(type)
        instance_classes.include?(type)
      end

      def configured_styles(content)
        if (styles = style_options)
          return styles.map { |s| content.class.find_named_style(s) }.compact
        end
      end

      def all_styles(content)
        content.class.styles
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
      #   :styles    => The list of (inline) style names that can be used by the pieces
      #   :prototype => The name of the prototype to use when creating pieces of this type
      #
      # TODO: finish these!
      def allow(type, options={}, &definition)
        allowed = AllowedType.new(self, type, options, &definition)
        allowed_types_config << allowed
        allowed
      end

      # TODO: implement this in a way that doesn't require searching through constants at load-time
      def allow_subclasses(type, options = {})
        parent_type = AllowedType.new(self, type)
        parent_type.allow_subclasses = true
        allowed_types_config << parent_type
        # parent_type.instance_class.subclasses.each do |subclass|
        #   allow(subclass, options)
        # end
      end

      def allow_group(*group_names)
        options = group_names.extract_options!
        allowed_types_config << AllowedGroup.new(self, group_names, options)
      end

      alias_method :allow_groups, :allow_group

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
    end # ClassMethods

    # InstanceMethods

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
        allowed.default_style(content)
      else
        content.default_style
      end
    end

    def available_styles(content)
      if allowed = allowed_type(content)
        allowed.styles(content)
      else
        content.class.styles
      end
    end
  end
end
