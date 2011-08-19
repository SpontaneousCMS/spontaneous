# encoding: UTF-8

module Spontaneous::Plugins
  module PageTree

    module InstanceMethods
      def ancestors
        @ancestors ||= ancestor_path.map { |id| Spontaneous::Content[id] }
      end

      def ancestor(depth)
        ancestors[depth]
      end

      def ancestor?(page)
        ancestor_path.include?(page.id)
      end

      def active?(page)
        page.id == self.id or ancestor?(page)
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

