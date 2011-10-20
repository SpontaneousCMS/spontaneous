# encoding: UTF-8

module Spontaneous::Plugins
  module Site
    module Schema
      module ClassMethods
        def schema
          instance.schema
        end
      end

      module InstanceMethods

        def uid
          schema.uids
        end

        def schema_id(obj)
          schema.schema_id(obj)
        end

        def schema
          @schema ||= Spontaneous::Schema::Schema.new(root, schema_loader_class)
        end

        def schema_loader_class
          @schema_loader_class ||= Spontaneous::Schema::PersistentMap
        end

        def schema_loader_class=(loader_class)
          @schema_loader_class = loader_class
        end
      end
    end
  end
end

