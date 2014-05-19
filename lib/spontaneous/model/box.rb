# encoding: UTF-8

module Spontaneous::Model
  module Box
    autoload :AllowedTypes,     "spontaneous/model/box/allowed_types"
    autoload :ContentHash,      "spontaneous/model/box/content_hash"

    extend Spontaneous::Concern

    module ClassMethods

      def inherited(subclass)
        subclass.instance_variable_set(:"@mapper", mapper)
        mapper.schema.inherited(self, subclass)
        super
      end
    end
  end
end
