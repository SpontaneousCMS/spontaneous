
module Spontaneous
  class FieldPrototype
    attr_reader :name

    def initialize(name, options={})
      @name = name
      parse_options(options)
    end


    def parse_options(options)
      @options = {
        :class => Spontaneous::Text,
        :default_value => '',
        :comment => false
      }.merge(options)
    end

    def field_class
      @options[:class]
    end

    def default_value
      @options[:default_value]
    end

    def comment
      @options[:comment]
    end
  end
end
