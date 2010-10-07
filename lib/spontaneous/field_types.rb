

module Spontaneous
  module FieldTypes
    @@type_map = {}

    def self.register(klass, *labels)
      labels.each do |label|
        @@type_map[label.to_sym] = klass
      end
    end

    def self.[](label)
      @@type_map[label.to_sym] || Text
    end
  end
end

require File.expand_path("../field_types/text", __FILE__)
require File.expand_path("../field_types/image", __FILE__)
require File.expand_path("../field_types/date", __FILE__)
