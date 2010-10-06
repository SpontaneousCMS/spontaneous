
module Spontaneous
  class Field
    attr_accessor :owner, :name, :raw_value, :value

    def initialize(attributes={})
      update(attributes)
    end

    def unprocessed_value=(v)
      self.raw_value = v
    end

    def raw_value=(v)
      @raw_value = v
      self.processed_value = process(@raw_value)
      owner.field_modified!(self) if owner
    end

    # should be overwritten in subclasses that actually do something
    # with the field value
    def process(value)
      value
    end

    # this little dance is to enable you to do field.value = "..."
    # rather than having to do field.raw_value = "..."
    # although it's a bit weird when you set value="Something"
    # and then read value and it's "Processed Something"
    # this is better than having to remember to do field.raw_value = "..."
    # every time
    # (semi colons are just to help out the indenter)
    alias_method :processed_value=, :value= ;
    alias_method :value=, :unprocessed_value= ;

    def serialize
      {
        :name => name,
        :raw_value => raw_value,
        :processed_value => value
      }
    end

    protected

    def update(attributes={})
      attributes.each do |property, value|
        setter = "#{property}=".to_sym
        if respond_to?(setter)
          self.send(setter, value)
        end
      end
    end
  end
end
