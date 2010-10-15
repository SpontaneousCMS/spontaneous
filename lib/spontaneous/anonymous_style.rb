
module Spontaneous
  class AnonymousStyle
    def template(format=:html)
      @template ||= AnonymousTemplate.new
    end
  end

  class AnonymousTemplate
    def render(binding)
      eval('render_content', binding)
    end
  end
end
