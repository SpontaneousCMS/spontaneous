# encoding: UTF-8

require 'hwia'

module Spontaneous
  class BoxPrototype

    attr_reader :name, :options, :owner

    def initialize(owner, name, options, &block)
      @owner = owner
      @name = name.to_sym
      @options = options
      @extend = block
    end

    def schema_id
      instance_class.schema_id
    end

    def schema_name
      instance_class.schema_name
    end

    def get_instance(owner)
      instance = instance_class.new(name, self, owner)
    end

    def field_defaults
      @options[:fields]
    end

    def instance_class
      @_instance_class ||= create_instance_class
    end

    def create_instance_class
      Class.new(box_base_class).tap do |instance_class|
        instance_class.class_eval(<<-RUBY)
            def self.schema_name
              "box/#{owner.schema_id}/#{self.name}"
            end
        RUBY
        if @extend
          instance_class.class_eval(&@extend)
        end
      end
      # else
      #   box_base_class
      # end
    end

    def box_base_class
      box_class = Spontaneous::Box
      class_name = @options[:type] || @options[:class]
      box_class = class_name.to_s.constantize if class_name
      box_class
    end

    def title
      @options[:title] || default_title
    end

    def default_style
      @options[:style]
    end

    def default_title
      name.to_s.titleize.gsub(/\band\b/i, '&')
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
    def readable?
      Spontaneous::Permissions.has_level?(read_level)
    end

    def writable?
      Spontaneous::Permissions.has_level?(write_level)
    end

    def style
      @options[:style]# || name
    end

    def readable_fields
      instance_class.readable_fields
    end

    def to_hash
      allowed_types = \
        if writable?
          instance_class.allowed_types.select { |type| type.readable? }.map { |type| type.instance_class.json_name }
        else
          []
        end
      {
        :name => name.to_s,
        :id => schema_id.to_s,
        :title => title,
        :writable => writable?,
        :allowed_types => allowed_types,
        :fields => readable_fields.map { |name| instance_class.field_prototypes[name].to_hash },
      }
    end
  end
end

