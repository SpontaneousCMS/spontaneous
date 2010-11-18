# encoding: UTF-8

module Spontaneous::Plugins
  module Render

    module ClassMethods
    end

    module InstanceMethods
      def render(format=:html, *args)
        Spontaneous::Render.render(self, format)
      end

      [:html].each do |format|
        module_eval("def to_#{format}(*args); render(:#{format}, *args); end")
      end
    end
  end
end

