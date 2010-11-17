# encoding: UTF-8

module Spontaneous::Plugins
  module Render

    module ClassMethods
    end

    module InstanceMethods
      def render(format=:html)
        Spontaneous::Render.render(self, format)
        # context = Spontaneous::RenderContext.new(self, format)
        # context.render
      end

      [:html].each do |format|
        module_eval("def to_#{format}; render(:#{format}); end")
      end
    end
  end
end

