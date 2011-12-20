# encoding: UTF-8

module Spontaneous::Plugins
  module Render
    extend ActiveSupport::Concern

    # InstanceMethods
    def render(format=:html, params={}, *args)
      if format.is_a?(Hash)
        params = format
        format = :html
      end
      Spontaneous::Render.render(self, format, params, *args)
    end
  end # Render
end
