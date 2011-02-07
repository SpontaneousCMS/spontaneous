# encoding: UTF-8


module Spontaneous
  module Render
    class PreviewRenderer < Renderer
      def render_content(content, format=:html, params = {})
        # render content using first_pass_renderer
        # then render this using second_pass_renderer
        template = preview_renderer.render_file(content.template, content, format, params)
        result = request_renderer.render_string(template, content, format, params)

        result
      end
    end # PreviewRenderer
  end # Render
end # Spontaneous

