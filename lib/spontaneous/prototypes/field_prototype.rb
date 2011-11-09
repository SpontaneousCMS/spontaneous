# encoding: UTF-8


module Spontaneous::Prototypes
  class FieldPrototype
    attr_reader :owner, :name

    def initialize(owner, name, type, options={})
      @owner = owner
      @name = name
      # if the type is nil then try the name, this will assign sensible defaults
      # to fields like 'image' or 'date'
      base_class = Spontaneous::FieldTypes[type || name]
      if block_given?
        @field_class = Class.new(base_class, &Proc.new)
        # @field_class.singleton_class.send(:define_method, :name) do
        #   base_class.name
        # end
      else
        @field_class = base_class
      end

      owner.const_set("#{name.to_s.camelize}Field", @field_class)

      # @field_class.prototype = self
      parse_options(options)
    end

    def schema_name
      "field/#{owner.schema_id}/#{name}"
    end

    def schema_id
      Spontaneous.schema.schema_id(self)
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

    def parse_options(options)
      @options = {
        :default => '',
        :comment => false
      }.merge(options)
    end

    def field_class
      @field_class
    end

    def default
      @options[:default]
    end

    def comment
      @options[:comment]
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

    def to_field(values=nil)
      default_values = values.nil?
      values = {
        :name => self.name,
        :unprocessed_value => default
      }.merge(values || {})
      self.field_class.new(values, !default_values).tap do |field|
        field.prototype = self
      end
    end

    def export(user)
      {
        :name => name.to_s,
        :schema_id => schema_id.to_s,
        :type => field_class.ui_class,
        :title => title,
        :comment => comment || "",
        :writable => Spontaneous::Permissions.has_level?(user, write_level)
      }
    end
  end
end
