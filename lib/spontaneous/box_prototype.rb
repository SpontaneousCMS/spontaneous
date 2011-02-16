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

    def get_instance(owner)
      instance = instance_class.new(name, self, owner)
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
  end
end

