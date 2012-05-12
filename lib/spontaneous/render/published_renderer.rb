# encoding: UTF-8

module Spontaneous
  module Render
    class PublishedRenderer < Renderer
      NGINX_DETECT_HEADER = "X-Nginx"
      NGINX_ACCEL_REDIRECT = "X-Accel-Redirect"

      def render_content(content, output=nil, params = {})
        output ||= content.output(:html)
        request  = params[:request]
        response = params[:response]
        headers  = request.env
        revision = Content.revision
        render   = nil

        if Spontaneous.development? and Spontaneous.config.rerender_pages
          # in dev mode we just want to render the page dynamically, skipping the cached version
          render = rerender(content, output, params)
        else
          # first test for dynamic template
          template = Spontaneous::Render.output_path(revision, output, true, request.request_method)

          if File.exists?(template)
            context = context_class(request_renderer, output).new(content, output.name, params)
            render  = request_renderer.render_file(template, context)
          else

            # if no dynamic template exists then try for a static file
            # this case will normally be handled by the proxy server (nginx, apache...)
            # in production environments
            template = Spontaneous::Render.output_path(revision, output, false, request.request_method)

            if File.exists?(template)
              render = File.open(template)
            else
              # and if all else fails, just re-render the damn thing
              render = rerender(content, output, params)
            end
          end
        end
        render
      end

      def rerender(content, output, params = {})
        template = S::Render.with_publishing_renderer do
          context = context_class(publishing_renderer, output).new(content, output.name)
          # publishing_renderer.render_file(content.template(output.name), context)
          output.render(params)
        end
        context = context_class(request_renderer, output).new(content, output.name, params)
        request_renderer.render_string(template, context)
      end

      # def render_string(template_string, content, format=:html, params = {})
      #   request_renderer.render_string(template_string, content, format, params)
      # end
    end # PublishedRenderer
  end # Render
end # Spontaneous
