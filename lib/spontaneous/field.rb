# encoding: UTF-8

module Spontaneous
  module Field
    autoload :Base,         "spontaneous/field/base"
    autoload :FieldVersion, "spontaneous/field/field_version"

    @@type_map = {}

    def self.register(klass, *labels)
      labels.each do |label|
        @@type_map[label.to_sym] = klass
      end
    end

    def self.[](label)
      @@type_map[label.to_sym] || String
    end

    def self.serialize_field(field)
      [field.schema_id.to_s, field.version, field.unprocessed_value, field.processed_values]
    end

    def self.deserialize_field(serialized_field)
      {
        :id => serialized_field[0],
        :version => serialized_field[1],
        :unprocessed_value => serialized_field[2],
        :processed_values => serialized_field[3]
      }
    end

  end
end

[:string, :long_string, :file, :image, :date, :markdown, :location, :webvideo, :select].each do |type|
  require "spontaneous/field/#{type}"
end
