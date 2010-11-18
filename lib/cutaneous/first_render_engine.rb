module Cutaneous
  class FirstRenderEngine < RenderEngine

    def initialize(template_root, context_class=PublishContext)
      super(template_root)
      @context_class = context_class
    end

    def template_class
      Cutaneous::Preprocessor
    end

  end
end



