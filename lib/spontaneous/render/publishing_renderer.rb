# encoding: UTF-8


module Spontaneous
  module Render
    class PublishingRenderer < Renderer
      def render_content(content, output=nil, params = {})
        output ||= content.output(:html)
        context  = context_class(publishing_renderer, output).new(content, output.name, params)
        publishing_renderer.render_file(content.template(output.name), context)
      end
      def render_string(template_string, content, output=nil, params = {})
        output ||= content.output(:html)
        context  = context_class(publishing_renderer, output).new(content, output.name, params)
        publishing_renderer.render_string(template_string, context)
      end

      def context_extensions
      end
    end # PublishingRenderer
  end  # Render
end  # Spontaneous

