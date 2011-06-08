# encoding: UTF-8

module Spontaneous::Plugins
  module Supertype
    module ClassMethods
      def supertype
        superclass
      end

      def supertype?
        !supertype.nil? #&& supertype.respond_to?(:field_prototypes)
      end
    end
  end
end
