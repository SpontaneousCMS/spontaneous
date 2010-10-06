
module Spontaneous
  class FieldPrototype
    attr_reader :name

    def initialize(name, options={})
      @name = name
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
      @options[:class]
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
