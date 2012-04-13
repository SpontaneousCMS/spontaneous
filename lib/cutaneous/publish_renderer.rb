# encoding: UTF-8

module Cutaneous
  class PublishRenderer < Renderer

    def template_class
      Cutaneous::PublishTemplate
    end

    def context_class
      Cutaneous::PublishContext
    end

    def context_extensions
      [Spontaneous::Render::PublishContext]
    end
  end
end
