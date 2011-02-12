# encoding: UTF-8

require 'hwia'

module Spontaneous
  class BoxPrototype

    attr_reader :name, :options

    def initialize(name, options)
      @name = name.to_sym
      @options = options
    end

    def get_instance(owner)
      instance = instance_class.new(name, self, owner)
    end

    def instance_class
      klass_name = @options[:type] || @options[:class]
      klass = Spontaneous::Box
      klass = klass_name.to_s.constantize if klass_name
      klass
    end

    def title
      @options[:title] || default_title
    end

    def default_title
      name.to_s.titleize.gsub(/\band\b/i, '&')
    end
  end
end

