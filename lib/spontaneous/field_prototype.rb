
module Spontaneous
  class FieldPrototype
    attr_reader :name

    def initialize(name, options={}, &block)
      @name = name
      @block = block
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
      if @block
        @field_class ||= Class.new(@options[:class], &@block)
      else
        @options[:class]
      end
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
