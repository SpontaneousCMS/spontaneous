# encoding: UTF-8

module Spontaneous::Plugins
  module PageTree

    module InstanceMethods
      def ancestors
        ancestor_path.map { |id| Spontaneous::Content[id] }
      end

      def ancestor(depth)
        ancestors[depth]
      end

      def generation
        parent ? parent.children : [root]
      end

      def siblings
        generation.reject { |p| p === self }
      end
    end
  end
end

