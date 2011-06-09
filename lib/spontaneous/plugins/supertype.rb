# encoding: UTF-8

module Spontaneous::Plugins
  module Supertype
    module ClassMethods
      def supertype
        superclass
      end
    end
  end
end
