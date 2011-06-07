# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaId

    module ClassMethods
      def schema_id
        Spontaneous::Schema.schema_id(self)
      end

      def schema_name
        "type//#{self.name}"
      end
    end # ClassMethods

    module InstanceMethods
      def schema_id
        self.class.schema_id
      end

      def schema_name
        self.class.schema_name
      end
    end # InstanceMethods
  end # SchemaId
end



