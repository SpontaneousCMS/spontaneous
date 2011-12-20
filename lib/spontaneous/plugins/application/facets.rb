# encoding: UTF-8

module Spontaneous::Plugins::Application
  module Facets
    extend ActiveSupport::Concern

    module ClassMethods
      def instance
        Spontaneous::Site.instance
      end

      def facets
        instance.facets
      end

      def schema
        instance.schema
      end

    end
  end
end
