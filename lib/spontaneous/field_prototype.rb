
module Spontaneous
  class FieldPrototype
    attr_reader :name

    def initialize(name, type, options={}, &block)
      @name = name
      @field_class = Spontaneous::FieldTypes[type]
      if block
        @field_class = Class.new(@field_class, &block)
      end
      parse_options(options)
    end


    def parse_options(options)
      @options = {
        :class => Spontaneous::FieldTypes::Text,
        :default_value => '',
        :comment => false
      }.merge(options)
    end

    def field_class
      @field_class
    end

    def default_value
      @options[:default_value]
    end

    def comment
      @options[:comment]
    end

    def to_field(values={})
      v = {
        :name => name,
        :value => default_value
      }.merge(values)
      self.field_class.new(v)
    end
  end
end
