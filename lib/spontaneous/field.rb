
module Spontaneous
  class Field
    attr_accessor :owner, :name, :raw_value, :value

    def initialize(attributes={})
      update(attributes)
    end

    def update(attributes={})
      attributes.each do |property, value|
        setter = "#{property}=".to_sym
        if respond_to?(setter)
          self.send(setter, value)
        end
      end
    end

    def unprocessed_value=(v)
      self.raw_value = v
    end

    alias_method :processed_value=, :value=
    alias_method :value=, :unprocessed_value=


    def raw_value=(v)
      @raw_value = v
      self.processed_value = process(@raw_value)
      # resource.field_modified!(self) if resource
    end

    # should be overwritten in subclasses that actually do something
    # with the field value
    def process(value)
      value
    end

  end
end
