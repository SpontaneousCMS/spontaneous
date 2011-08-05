# encoding: UTF-8


module Spontaneous::Plugins::Application
  module Facets
    module ClassMethods
      def instance
        @instance ||= nil
      end

      def instance=(instance)
        # unless @instance
        @instance = instance
          # facets << instance
        # end
      end

      def facets
        Spontaneous::Site.instance.facets
      end

    end
  end
end

