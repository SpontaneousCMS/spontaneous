# encoding: UTF-8


module Spontaneous
  module Render
    class PublishedRenderer < Renderer
      def render_content(content, format=:html, params = {})
        if Spontaneous.development? or Spontaneous.test?
          # in dev mode we just want to render the page dynamically, skipping the cached version
          template = publishing_renderer.render_file(content.template, content, format, params)
          result = request_renderer.render_string(template, content, format, params)
        else
          # then we need to look for a pre-rendered version of the file and render it
          # TODO: write this with tests!
        end
      end
    end # PublishedRenderer
  end # Render
end # Spontaneous


