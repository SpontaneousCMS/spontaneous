# encoding: UTF-8

module Spontaneous::Model::Core
  module Supertype
    extend Spontaneous::Concern

    module ClassMethods
      def supertype
        superclass
      end
    end # ClassMethods
  end
end
