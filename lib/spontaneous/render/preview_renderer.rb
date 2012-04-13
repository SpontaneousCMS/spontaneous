# encoding: UTF-8


module Spontaneous
  module Render
    class PreviewRenderer < Renderer
      def render_content(content, output, params = {})
        # render content using first_pass_renderer
        # then render this using second_pass_renderer
        context  = context_class(preview_renderer, output).new(content, output.name, params)
        template = preview_renderer.render_file(content.template(output.name), context)

        context = context_class(request_renderer, output).new(content, output.name, params)
        result   = request_renderer.render_string(template, context)
        result
      end

      def render_string(template_string, content, output, params = {})
        context  = context_class(preview_renderer, output).new(content, output.name, params)
        template = preview_renderer.render_string(template_string, context)

        context  = context_class(request_renderer, output).new(content, output.name, params)
        result   = request_renderer.render_string(template, context)
        result
      end
    end # PreviewRenderer
  end # Render
end # Spontaneous

