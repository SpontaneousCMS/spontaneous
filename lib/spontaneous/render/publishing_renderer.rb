# encoding: UTF-8


module Spontaneous
  module Render
    class PublishingRenderer < Renderer
      def render_content(content, format=:html, params = {})
        publishing_renderer.render_file(content.template(format), content, format, params)
      end
    end # PublishingRenderer
  end  # Render
end  # Spontaneous

