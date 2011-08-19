# encoding: UTF-8

module Spontaneous::Plugins
  module Render

    module ClassMethods
    end

    module InstanceMethods
      def render(format=:html, params={}, *args)
        if format.is_a?(Hash)
          params = format
          format = :html
        end
        Spontaneous::Render.render(self, format, params, *args)
      end

      # [:html].each do |format|
      #   module_eval("def to_#{format}(*args); render(:#{format}, *args); end")
      # end
    end
  end
end

