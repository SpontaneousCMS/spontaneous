# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Schema
    extend Spontaneous::Concern

    module ClassMethods
      def schema
        instance.schema
      end
    end # ClassMethods

    def uid
      schema.uids
    end

    def schema_id(obj)
      schema.to_id(obj)
    end

    def schema
      @schema ||= Spontaneous::Schema::Schema.new(root, schema_loader_class)
    end

    def schema_loader_class
      @schema_loader_class ||= Spontaneous::Schema::PersistentMap
    end

    def schema_loader_class=(loader_class)
      schema.schema_loader_class = (@schema_loader_class = loader_class)
    end
  end
end
