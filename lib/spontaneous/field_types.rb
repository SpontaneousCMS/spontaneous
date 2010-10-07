

module Spontaneous
  module FieldTypes
    @@type_map = {}

    def self.register(klass, *labels)
      labels.each do |label|
        @@type_map[label.to_sym] = klass
      end
    end

    def self.[](label)
      @@type_map[label.to_sym] || StringField
    end
  end
end

require File.expand_path("../field_types/string_field", __FILE__)
require File.expand_path("../field_types/image_field", __FILE__)
require File.expand_path("../field_types/date_field", __FILE__)
