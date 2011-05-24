# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaId

    module ClassMethods
      def schema_id
        Spontaneous::Schema.schema_id(self)
      end

      def schema_name
        self.name
      end
    end # ClassMethods
  end # SchemaId
end



