# encoding: UTF-8

module Cutaneous
  class SecondPassRenderer < Renderer

    def initialize(template_root, context_class=RequestContext)
      super(template_root, context_class)
    end

    def template_class
      Cutaneous::SecondPassParser
    end

  end
end



