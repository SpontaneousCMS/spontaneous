
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

    def self.prototype=(prototype)
      @prototype = prototype
    end
    def self.prototype
      @prototype
    end
    attr_accessor :owner, :name, :unprocessed_value


    def initialize(attributes={}, from_db=false)
      update(attributes, from_db)
    end


    def unprocessed_value=(v)
      @unprocessed_value = v
      unless @preprocessed
        self.processed_value = process(@unprocessed_value)
        owner.field_modified!(self) if owner
      end

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

    def processed_value
      @processed_value
    end

    def to_s
      value.to_s
    end

    def value=(value)
      self.unprocessed_value = value
    end

    def prototype
      self.class.prototype
    end

    def serialize
      {
        :name => name,
        :unprocessed_value => unprocessed_value,
        :processed_value => processed_value
      }
    end

    protected

    def update(attributes={}, from_db=false)
      @preprocessed = from_db
      attributes.each do |property, value|
        setter = "#{property}=".to_sym
        if respond_to?(setter)
          self.send(setter, value)
        end
      end
      @preprocessed = nil
    end

    def processed_value=(value)
      @processed_value = value
    end
  end
end
