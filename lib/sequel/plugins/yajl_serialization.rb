# encoding: UTF-8

require 'sequel/plugins/serialization'

module Sequel
  module Plugins
    module YajlSerialization

      def self.parse(json)
        parser.parse(json)
      end

      def self.parser
        Yajl::Parser.new(:symbolize_keys => true)
      end

      def self.encode(obj)
        encoder.encode(obj)
      end

      def self.encoder
        Yajl::Encoder.new
      end

      # Set up the column readers to do deserialization and the column writers
      # to save the value in deserialized_values.
      def self.apply(model, *args)
        model.instance_eval{@serialization_map = {}}
      end

      def self.configure(model, *columns)
        model.serialize_attributes(:json, *columns) unless columns.empty?
      end

      module ClassMethods
        include ::Sequel::Plugins::Serialization::ClassMethods
      end

      module InstanceMethods
        include ::Sequel::Plugins::Serialization::InstanceMethods

        private

        # Deserialize the column from JSON format
        def deserialize_value(column, v)
          return v if v.nil?
          YajlSerialization.parse(v)
        end

        # Serialize the column to JSON format
        def serialize_value(column, v)
          return v if v.nil?
          YajlSerialization.encode(v)
        end
      end
    end
  end
end
