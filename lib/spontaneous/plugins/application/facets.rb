# encoding: UTF-8


module Spontaneous::Plugins::Application
  module Facets
    module ClassMethods
      def instance
        Spontaneous::Site.instance
      end

      # def instance=(instance)
      #   # unless @instance
      #   @instance = instance
      #     # facets << instance
      #   # end
      # end

      def facets
        instance.facets
      end

      def schema
        instance.schema
      end

    end
  end
end

