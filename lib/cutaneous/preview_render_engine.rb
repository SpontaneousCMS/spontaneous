module Cutaneous
  class RerenderEngine < SecondRenderEngine
    def render_result(template_string, content, format, params={})
      context = context_class.new(content, format, params)
      hook_context(context)
      template = template_class.new
      template.convert(template_string)
      template.render(context)
    end
  end

  class PreviewRenderEngine < RenderEngine
    def first_render_engine
      @first_render_engine ||= FirstRenderEngine.new(@template_root, PreviewContext)
    end

    def second_render_engine
      @second_render_engine ||= RerenderEngine.new(@template_root)
    end

    def render_content(content, format=:html, params={})
      template = first_render_engine.render_content(content, format)
      result = second_render_engine.render_result(template, content, format, params)
      # first render using a FirstRenderEngine and a PreviewContext
      # then render the result of that using a SecondRenderEngine and a RequestContext
      result
    end
  end
end



