# encoding: UTF-8


module Spontaneous::Prototypes
  # FieldPrototype represents the class-level view of a type field.
  # It contains information on the type of the field and the options
  # passed in the type declaration and is responsible for transforming
  # serialized field data from the db into a field instance.
  #
  # options - A hash containing options that control the behaviour of the
  #           field (default: {})
  #
  #           :default  - The default value for new fields. This accepts either a
  #                       value (which is either a String or responds to #to_s)
  #                       or a Proc value generator which can accept 1 argument
  #                       that is the instance that the field is attached to.
  #           :title    - The title that should be used to label the field in the UI.
  #                       This defaults to the 'titleized' version of the field name,
  #                       e.g. ':field_name' becomes 'Field Name'.
  #           :comment  - An optional String comment to be displayed in the UI
  #                       (default: "").
  #           :list     - A Boolean flag determining whether to show the field in the
  #                       list view (default: true).
  #           :fallback - Provides a way of supplying a fallback value for an empty
  #                       field.
  #
  #           Other options are dependent on the type of field.
  #
  # Examples
  #
  # Pass a Proc as the default value for a field:
  #
  #   field :title, default: proc { |page| "This is page #{page.slug}" }
  #
  # Assign a field with a fallback:
  #
  #   class Something < Piece
  #     field :a
  #     field :b, fallback: :a
  #   end
  #
  #   instance = Something.new(a: "The value of A")
  #   instance.a.value #=> "The value of A"
  #   instance.b.value #=> "The value of A"
  #   instance.b = "Now B"
  #   instance.b.value #=> "Now B"
  #
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
      Spontaneous::Schema.schema_name('field', owner.schema_id, name)
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

    def default(instance = nil)
      instance_class.make_default_value(instance, default_value_for_instance(instance))
    end

    def default_value_for_instance(instance)
      case (default = @options[:default])
      when Proc
        default[instance]
      else
        default
      end
    end

    def dynamic_default?
      @options[:default].is_a?(Proc)
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
      search(index.site).in_index?(index)
    end

    def index_id(index)
      search(index.site).index_id(index)
    end

    def options_for_index(index)
      search(index.site).field_definition(index)
    end

    # TODO: it's wrong to have to be passing the site to this call
    # as there's only ever one site and we shouldn't be memoizing
    # a method call with a param.
    # Must centralize the testing of a prototype for inclusion into
    # an index - either into the index or the site itself.
    # We can't just recalculate this on the fly because indexing
    # needs to be reasonably performant.
    def search(site)
      @search ||= S::Search::Field.new(site, self, @options[:index])
    end

    def inherit_schema_id(schema_id)
      @_inherited_schema_id = schema_id.to_s
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
      field = self.instance_class.new(values, using_default_values)
      field.prototype = self
      field
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
