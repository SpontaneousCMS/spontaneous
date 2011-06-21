# encoding: UTF-8


module Spontaneous::Plugins
  module Fields
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
          @field_class.meta.send(:define_method, :name) do
            base_class.name
          end
        else
          @field_class = base_class
        end

        # @field_class.prototype = self
        parse_options(options)
      end

      def schema_name
        "field/#{owner.schema_id}/#{name}"
      end

      def schema_id
        Spontaneous::Schema.schema_id(self)
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

      def to_field(values=nil)
        from_db = !values.nil?
        values = {
          :name => name,
          :unprocessed_value => default
        }.merge(values || {})
        field = self.field_class.new(values, from_db)
        field.prototype = self
        field
      end

      def to_hash
        {
          :name => name.to_s,
          :type => field_class.json_name,
          :title => title,
          :comment => comment || "",
          :writable => Spontaneous::Permissions.has_level?(write_level)
        }
      end
    end
  end
end
