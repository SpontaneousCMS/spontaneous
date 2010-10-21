

module Spontaneous
  module FieldTypes

    autoload :Base, "spontaneous/field_types/base"

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

[:string, :image, :date, :discount].each do |type|
  require "spontaneous/field_types/#{type}_field"
end
