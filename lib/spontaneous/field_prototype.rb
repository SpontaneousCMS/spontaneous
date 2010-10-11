
module Spontaneous
  class FieldPrototype
    attr_reader :name

    def initialize(name, type, options={}, &block)
      @name = name
      @field_class = Spontaneous::FieldTypes[type]
      if block
        @field_class = Class.new(@field_class, &block)
      end
      @field_class.prototype = self
      parse_options(options)
    end

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
        :unprocessed_value => default_value
      }.merge(values)
      self.field_class.new(v)
    end
  end
end
