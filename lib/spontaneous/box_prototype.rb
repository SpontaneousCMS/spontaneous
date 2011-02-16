# encoding: UTF-8

require 'hwia'

module Spontaneous
  class BoxPrototype

    attr_reader :name, :options

    def initialize(name, options, &block)
      @name = name.to_sym
      @options = options
      @extend = block
    end

    def schema_id
      name.to_s
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
      if @extend
        Class.new(box_base_class).tap do |instance_class|
          instance_class.class_eval(&@extend)
        end
      else
        box_base_class
      end
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

    def default_title
      name.to_s.titleize.gsub(/\band\b/i, '&')
    end

    def style
      @options[:style]# || name
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

    def readable_fields
      instance_class.readable_fields
    end

  end
end

