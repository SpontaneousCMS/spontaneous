# encoding: UTF-8

class Spontaneous::Site
  module Schema
    extend Spontaneous::Concern

    def uid
      schema.uids
    end

    def schema_id(obj)
      schema.to_id(obj)
    end

    def schema
      @schema ||= Spontaneous::Schema::Schema.new(self, root, schema_loader_class)
    end

    def schema_loader_class
      @schema_loader_class ||= Spontaneous::Schema::PersistentMap
    end

    def schema_loader_class=(loader_class)
      schema.schema_loader_class = (@schema_loader_class = loader_class)
    end
  end
end
