# encoding: UTF-8

module Cutaneous
  class PreviewRenderer < PublishRenderer

    def context_class
      Cutaneous::PreviewContext
    end

    def context_extensions
      [Spontaneous::Render::PreviewContext]
    end
  end
end
