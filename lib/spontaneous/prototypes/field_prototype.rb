# encoding: UTF-8


module Spontaneous::Prototypes
  class FieldPrototype
    attr_reader :owner, :name, :options

    def initialize(owner, name, type, options={}, blocks = [], &block)
      @owner = owner
      @name = name
      @extend = [blocks].flatten.push(block).compact

      # if the type is nil then try the name, this will assign sensible defaults
      # to fields like 'image' or 'date'
      @base_class = Spontaneous::Field[type || name]

      parse_options(@base_class, options)


      field_class_name = "#{name.to_s.camelize}Field"
      owner.const_set(field_class_name, instance_class)

      self
    end

    def schema_name
      "field/#{owner.schema_id}/#{name}"
    end

    def schema_id
      Spontaneous.schema.uids[@_inherited_schema_id] || Spontaneous.schema.to_id(self)
    end

    def schema_owner
      owner
    end

    def owner_sid
      schema_owner.schema_id
    end

    # alias_method :id, :schema_id

    def title(new_title=nil)
      self.title = new_title if new_title
      @title || @options[:title] || default_title
    end

    def title=(new_title)
      @title = new_title
    end

    def default_title
      @name.to_s.titleize
    end

    def parse_options(field_class, options)
      @options = default_options(field_class).merge(options)
    end

    def default_options(field_class)
      {default: '', comment: false, list: true}.merge(field_class.default_options)
    end

    def instance_class
      @_instance_class ||= create_instance_class
    end

    def create_instance_class
      base_class = @base_class
      Class.new(@base_class).tap do |instance_class|
        # although we're subclassing the base field class, we don't want the ui
        # to use a different editor. FieldClass::editor_class is used in the serialisation
        # routine
        # instance_class.singleton_class.send(:define_method, :editor_class) do
        #   base_class.editor_class
        # end
        @extend.each { |block|
          instance_class.class_eval(&block) if block
        }
        instance_class.prototype = self
      end
    end

    def field_class
      instance_class
    end

    def default(_instance = nil)
      case default = @options[:default]
      when Proc
        default[_instance]
      else
        default
      end
    end

    def comment
      @options[:comment]
    end

    def fallback
      @options[:fallback]
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

    def in_index?(index)
      search.in_index?(index)
    end

    def index_id(index)
      search.index_id(index)
    end

    def options_for_index(index)
      search.field_definition(index)
    end

    def search
      @search ||= S::Search::Field.new(self, @options[:index])
    end

    def inherit_schema_id(schema_id)
      @_inherited_schema_id = schema_id.to_s
      # instance_class.schema_id = schema_id
    end

    def merge(subclass_owner, field_type, subclass_options, &subclass_block)
      options = @options.merge(subclass_options)
      self.class.new(subclass_owner, name, field_type, options, @extend, &subclass_block).tap do |prototype|
        prototype.inherit_schema_id self.schema_id
      end
    end

    def to_field(instance, database_values=nil)
      using_default_values = database_values.nil?
      values = { :name => self.name }
      values[:unprocessed_value] = default(instance) if using_default_values
      values.update(database_values || {})
      self.instance_class.new(values, using_default_values).tap do |field|
        field.prototype = self
      end
    end

    def export(user)
      {
        name: name.to_s,
        schema_id: schema_id.to_s,
        type: instance_class.editor_class,
        title: title,
        comment: comment || "",
        list: @options[:list] || false,
        writable: Spontaneous::Permissions.has_level?(user, write_level)
      }.merge(instance_class.export(user))
    end
  end
end
