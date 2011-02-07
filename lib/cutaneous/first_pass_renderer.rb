# encoding: UTF-8

module Cutaneous
  class FirstPassRenderer < Renderer

    def initialize(template_root, context_class=PublishContext)
      super(template_root, context_class)
    end

    def template_class
      Cutaneous::FirstPassParser
    end

  end
end




