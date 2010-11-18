module Cutaneous
  class SecondRenderEngine < RenderEngine

    def initialize(template_root, context_class=RequestContext)
      super(template_root)
      @context_class = context_class
    end

    def template_class
      Cutaneous::Template
    end

  end
end


