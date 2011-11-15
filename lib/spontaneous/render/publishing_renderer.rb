# encoding: UTF-8


module Spontaneous
  module Render
    class PublishingRenderer < Renderer
      def render_content(content, format=:html, params = {})
        publishing_renderer.render_file(content.template(format), content, format, params)
      end
      def render_string(template_string, content, format=:html, params = {})
        publishing_renderer.render_string(template_string, content, format, params)
      end
    end # PublishingRenderer
  end  # Render
end  # Spontaneous

