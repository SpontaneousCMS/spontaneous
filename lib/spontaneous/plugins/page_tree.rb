module Spontaneous::Plugins
  module PageTree

    module InstanceMethods
      def ancestors
        node, nodes = self, []
        nodes << node = node.parent while node.parent
        nodes
      end

      def generation
        parent ? parent.children : root
      end

      def siblings
        generation.reject { |p| p === self }
      end
    end
  end
end

