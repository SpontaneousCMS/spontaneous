
module Spontaneous
  class Slot
    attr_reader :name

    def initialize(name, options={})
      @name = name.to_sym
      @options = options
    end

    def title
      @options[:title] || default_title
    end

    def group
      @options[:group]
    end

    def default_title
      name.to_s.titleize
    end

    def instance_class
      @instance_class ||= \
        case klass = @options[:class]
        when Class
          klass
        when String, Symbol
          klass.to_s.constantize
        else
          Facet
        end
    end
  end
end

