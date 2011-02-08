# encoding: UTF-8


module Spontaneous
  module Render
    class PublishedRenderer < Renderer
      def render_content(content, format=:html, params = {})
        render = nil
        if Spontaneous.development?
          # in dev mode we just want to render the page dynamically, skipping the cached version
          render = rerender(content, format, params)
        else
          # first test for dynamic template
          template = Spontaneous::Render.output_path(Content.revision, content, format, extension)

          if File.exists?(template)
            render = request_renderer.render_file(template, content, format, params)
          else

            # if no dynamic template exists then try for a static file
            # this case will normally be handled by the proxy server (nginx, apache...)
            # in production environments
            template = Spontaneous::Render.output_path(Content.revision, content, format)

            if File.exists?(template)
              render = File.read(template)
            else
              # and if all else fails, just re-render the damn thing
              render = rerender(content, format, params)
            end
          end
        end
        render
      end

      def rerender(content, format = :html, params = {})
        template = publishing_renderer.render_file(content.template, content, format)
        request_renderer.render_string(template, content, format, params)
      end

      def cache?
        true
      end
    end # PublishedRenderer
  end # Render
end # Spontaneous

