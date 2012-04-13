# encoding: UTF-8

module Cutaneous
  class RequestRenderer < Renderer

    def template_class
      Cutaneous::RequestTemplate
    end

    def context_class
      Cutaneous::RequestContext
    end

    def context_extensions
      [Spontaneous::Render::RequestContext]
    end
  end
end
