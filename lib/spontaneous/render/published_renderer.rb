# encoding: UTF-8

module Spontaneous
  module Render
    class PublishedRenderer < Renderer
      NGINX_DETECT_HEADER = "X-Nginx"
      NGINX_ACCEL_REDIRECT = "X-Accel-Redirect"

      def render_content(content, format=:html, params = {})
        request = params[:request]
        response = params[:response]
        headers = request.env
        render = nil
        if Spontaneous.development? and Spontaneous.config.rerender_pages
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
              # first check to see if we're behind an nginx proxy
              if headers.key?(NGINX_DETECT_HEADER)
                # if so, then use nginx's sendfile mechanism to return the file
                response.headers[NGINX_ACCEL_REDIRECT] = Spontaneous::Render.redirect_path(Content.revision, content, format)
              else
                # if not, then return the file ourselves
                render = File.read(template)
              end
            else
              # and if all else fails, just re-render the damn thing
              render = rerender(content, format, params)
            end
          end
        end
        render
      end

      def rerender(content, format = :html, params = {})
        template = publishing_renderer.render_file(content.template(format), content, format)
        request_renderer.render_string(template, content, format, params)
      end
    end # PublishedRenderer
  end # Render
end # Spontaneous
