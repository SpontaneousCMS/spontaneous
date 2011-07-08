# encoding: UTF-8


module Spontaneous::Plugins::Application
  module Facets
    module ClassMethods
      def instance
        @instance ||= nil
      end

      def instance=(instance)
        unless @instance
          @instance = instance
          facets << instance
        end
      end

      def facets
        @facets ||= []
      end

      def load_plugin(plugin_root)
        plugin = Spontaneous::Application::Plugin.new(plugin_root)
        self.facets <<  plugin
        plugin
      end
    end
  end
end

