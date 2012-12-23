# encoding: UTF-8

module Spontaneous::Model::Core
  module Render
    extend Spontaneous::Concern

    def output(format = :html)
      return page.output(format, self) if page
      raise "Cannot render content without enclosing page"
    end

    def render(format = :html, params = {}, *args)
      params, format = format, :html if format.is_a?(Hash)
      output(format).render(params, *args)
    end

    def render_using(renderer, format = :html, params = {}, *args)
      output(format).render_using(renderer, params, *args)
    end
  end
end
