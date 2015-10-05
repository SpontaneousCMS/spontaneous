# encoding: UTF-8


module Spontaneous::Prototypes
  class BoxPrototype

    attr_reader :name, :options, :owner

    def initialize(owner, name, options, blocks = [], &block)
      @owner = owner
      @name = name.to_sym
      @options = options
      @extend = [blocks].flatten.push(block).compact
      instance_class
      self
    end

    def position
      owner.box_position(self)
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
      Spontaneous.schema.uids[@_inherited_schema_id] || instance_class.schema_id
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

    def inherit_schema_id(schema_id)
      @_inherited_schema_id = instance_class.schema_id = schema_id.to_s
    end

    def merge(subclass_owner, subclass_options, &subclass_block)
      options = @options.merge(subclass_options)
      Spontaneous::Prototypes::BoxPrototype.new(subclass_owner, name, options, @extend, &subclass_block).tap do |prototype|
        # We want merged boxes, which are essentially monkey-patched box definitions
        # to use the same schema id as the supertype version because otherwise removing the
        # subtype version and falling back to the original supertype definition would remove
        # all the content from the box while the box itself would still remain visible in the UI
        prototype.inherit_schema_id self.schema_id
      end
    end

    def create_instance_class
      Class.new(box_base_class).tap do |instance_class|
        # doing this means we get proper names for the anonymous box classes
        owner.const_set("#{name.to_s.camelize}Box", instance_class)
        box_owner = owner
        box_name = name
        marked_as_generated = generated?
        instance_class.instance_eval do
          singleton_class.__send__(:define_method, :schema_name) do
            Spontaneous::Schema.schema_name('box', box_owner.schema_id, box_name)
          end
          singleton_class.__send__(:define_method, :schema_owner) do
            box_owner
          end
          singleton_class.__send__(:define_method, :owner_sid) do
            box_owner.schema_id
          end
          singleton_class.__send__(:define_method, :method_added) do |method|
            if [:contents].include?(method) # maybe need to expand the list of 'dangerous' methods
              logger.warn("#{box_owner} box '#{box_name}': redefining the #contents method. You should set 'generated: true' in the box options unless the box contents are entirely under user control")
            end
          end unless marked_as_generated
        end
        @extend.each { |block|
          instance_class.class_eval(&block) if block
        }
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
      defined?(::Box) ? ::Box : owner.content_model::Box
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

    # If a box is marked as 'generated' then its contents
    # are not under user control & it should be skipped when
    # calculating the owner's content hash
    def generated?
      @options[:generated] || false
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

    def allow(*args)
      instance_class.allow(*args)
    end

    def allowed_types(user)
      _allowed(user).flat_map { |allow| allow.instance_classes }
    end

    def _allowed(user)
      return [] unless writable?(user)
      instance_class.allowed.select { |a| a.readable?(user) }
    end

    private :_allowed

    def export(user)
      allowed = _allowed(user).flat_map { |a| a.export }
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
