# encoding: UTF-8

module Spontaneous::Plugins
  module Supertype
    extend ActiveSupport::Concern

    module ClassMethods
      def supertype
        superclass
      end
    end # ClassMethods
  end
end
