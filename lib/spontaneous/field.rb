
module Spontaneous
  class Field


    def self.register(*labels)
      labels = self.labels if labels.empty?
      FieldTypes.register(self, *labels)
      self
    end

    def self.labels
      [self.name.demodulize.gsub(/Field$/, '').underscore]
    end

    attr_accessor :owner, :name, :unprocessed_value, :processed_value

    def initialize(attributes={})
      update(attributes)
    end


    def unprocessed_value=(v)
      @unprocessed_value = v
      self.processed_value = process(@unprocessed_value)
      owner.field_modified!(self) if owner
    end

    # should be overwritten in subclasses that actually do something
    # with the field value
    def process(value)
      value
    end

    # override this to return custom values derived from (un)processed_value
    def value
      processed_value
    end

    def to_s
      value.to_s
    end

    def value=(value)
      self.unprocessed_value = value
    end


    def serialize
      {
        :name => name,
        :unprocessed_value => unprocessed_value,
        :processed_value => processed_value
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
