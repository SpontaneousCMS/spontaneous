module Spontaneous::Plugins
  module Render

    module ClassMethods
    end

    module InstanceMethods
      def render(format=:html)
        context = Spontaneous::RenderContext.new(self, format)
        context.render
      end
    end
  end
end

