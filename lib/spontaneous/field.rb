
module Spontaneous
  class Field
    attr_accessor :owner, :name, :raw_value, :value

    def initialize(attributes)
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
  end
end
