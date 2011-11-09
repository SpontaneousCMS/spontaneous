# encoding: UTF-8


module Spontaneous::Prototypes
  class BoxPrototype

    attr_reader :name, :options, :owner

    def initialize(owner, name, options, &block)
      @owner = owner
      @name = name.to_sym
      @options = options
      @extend = block
      instance_class
      self
    end

    def __source_file
      owner.__source_file
    end

    def field_prototypes
      instance_class.field_prototypes
    end

    def style_prototypes
      instance_class.style_prototypes
    end

    def schema_id
      instance_class.schema_id
    end


    def schema_name
      instance_class.schema_name
    end

    def schema_owner
      owner
    end

    def owner_sid
      schema_owner.schema_id
    end

    def get_instance(owner)
      instance = instance_class.new(name, self, owner)
    end

    def field_defaults
      @options[:fields]
    end

    def group
      @options[:group]
    end

    def instance_class
      @_instance_class ||= create_instance_class
    end

    def create_instance_class
      Class.new(box_base_class).tap do |instance_class|
        # doing this means we get proper names for the anonymous box classes
        owner.const_set("#{name.to_s.camelize}Box", instance_class)
        box_owner = owner
        box_name = name
        instance_class.instance_eval do
          singleton_class.__send__(:define_method, :schema_name) do
            "box/#{box_owner.schema_id}/#{box_name}"
          end
          singleton_class.__send__(:define_method, :schema_owner) do
            box_owner
          end
          singleton_class.__send__(:define_method, :owner_sid) do
            box_owner.schema_id
          end
        end
        if @extend
          instance_class.class_eval(&@extend)
        end
      end.tap do |klass|
        # Spontaneous.schema.classes << klass# if subclass.schema_class?
      end
    end

    def box_base_class
      box_class = default_box_class
      class_name = @options[:type] || @options[:class]
      box_class = class_name.to_s.constantize if class_name
      # box_class = Class.new(box_class) do
      #   def self.inherited(subclass)
      #     subclasses << subclass
      #   end
      # end
      box_class
    end

    def default_box_class
      defined?(::Box) ? ::Box : Spontaneous::Box
    end

    ## failed attempt to exclude anonymous boxes from the list of schema classes
    ## actually easier to keep them in, despite later problems with UID creation
    ## because this way their fields & styles are automatically validated
    # class AnonymousBox < Spontaneous::Box
    #   def self.schema_class?
    #     false
    #   end
    # end

    def title
      @options[:title] || default_title
    end

    def default_style
      @options[:style]
    end

    def default_title
      name.to_s.titleize.gsub(/\band\b/i, '&')
    end

    def field_prototypes
      instance_class.field_prototypes
    end

    # default read level is None, i.e. every logged in user can read the field
    def read_level
      level_name = @options[:read_level] || @options[:user_level] || :none
      Spontaneous::Permissions[level_name]
    end

    # default write level is the first level above None
    def write_level
      level_name = @options[:write_level] || @options[:user_level] || Spontaneous::Permissions::UserLevel.minimum.to_sym
      Spontaneous::Permissions[level_name]
    end

    # TODO: must be able to make these into a module
    def readable?(user)
      Spontaneous::Permissions.has_level?(user, read_level)
    end

    def writable?(user)
      Spontaneous::Permissions.has_level?(user, write_level)
    end

    def style
      @options[:style]# || name
    end

    def readable_fields(user)
      instance_class.readable_fields(user)
    end

    def allowed_types(user)
      if writable?(user)
        types = []
        instance_class.allowed.select { |a| a.readable?(user) }.each do  |a|
          types.concat(a.instance_classes)
        end
        types
      else
        []
      end
    end

    def export(user)
      allowed = allowed_types(user).map { |c| c.ui_class }
      {
        :name => name.to_s,
        :id => schema_id.to_s,
        :title => title,
        :writable => writable?(user),
        :allowed_types => allowed,
        :fields => readable_fields(user).map { |name| instance_class.field_prototypes[name].export(user) },
      }
    end
  end
end
