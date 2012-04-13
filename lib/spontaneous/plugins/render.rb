# encoding: UTF-8

module Spontaneous::Plugins
  module Render
    extend ActiveSupport::Concern

    def output(format = :html)
      return page.output(format) if page
      # this only really happens in
      # Spontaneous::Render::Output.create(format)
    end

    # InstanceMethods
    def render(format=:html, params={}, *args)
      if format.is_a?(Hash)
        params = format
        format = :html
      end
      Spontaneous::Render.render(self, output(format), params, *args)
    end
  end # Render
end
