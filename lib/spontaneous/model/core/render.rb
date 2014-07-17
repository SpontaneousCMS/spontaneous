# encoding: UTF-8

module Spontaneous::Model::Core
  module Render
    extend Spontaneous::Concern

    def output(format = :html)
      return page.output(format, self) if page
      raise "Cannot render content without enclosing page"
    end

    def render(format = :html, params = {}, parent_context = nil)
      params, format = format, :html if format.is_a?(Hash)
      output(format).render(params, parent_context)
    end

    def render_using(renderer, format = :html, params = {}, parent_context = nil)
      output(format).render_using(renderer, params, parent_context)
    end

    alias_method :render_inline, :render
    alias_method :render_inline_using, :render_using
  end
end
