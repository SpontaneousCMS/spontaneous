# encoding: UTF-8


module Spontaneous
  module Render
    class DevelopmentRenderer < Renderer
      def render_content(content, format=:html, params = {})
        template = publishing_renderer.render_file(content.template, content, format, params)
        result = request_renderer.render_string(template, content, format, params)
      end
    end # DevelopmentRenderer
  end # Render
end # Spontaneous

