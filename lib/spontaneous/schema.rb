# encoding: UTF-8


module Spontaneous
  module Schema
    class << self


      def validate!
        validate_schema
      end

      def validate_schema
        self.classes.each do | schema_class |
          schema_class.schema_validate
        end
      end


      def to_hash
        self.classes.inject({}) do |hash, klass|
          hash[klass.name] = klass.to_hash
          hash
        end
      end

      def to_json
        to_hash.to_json
      end

      def classes
        classes = []
        Content.subclasses.each do |klass|
          recurse_classes(klass, classes)
        end
        classes
      end

      def recurse_classes(root_class, list)
        root_class.subclasses.each do |klass|
          list << klass
          recurse_classes(klass, list)
        end
      end
    end
  end
end
