# encoding: UTF-8


module Spontaneous
  module Render
    class PublishedRenderer < Renderer
      def render_content(content, format=:html, params = {})
        # in dev mode we just want to render the page dynamically, skipping the cached version
        if Spontaneous.development? or Spontaneous.test?
          template = publishing_renderer.render_file(content.template, content, format, params)
          result = request_renderer.render_string(template, content, format, params)
        end
      end
    end # PublishedRenderer
  end # Render
end # Spontaneous


