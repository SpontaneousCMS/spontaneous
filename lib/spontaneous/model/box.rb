# encoding: UTF-8

module Spontaneous::Model
  module Box
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
