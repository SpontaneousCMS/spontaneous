# encoding: UTF-8

module Cutaneous
  class SecondPassRenderer < Renderer

    def template_class
      Cutaneous::SecondPassParser
    end

    def context_class
      Cutaneous::RequestContext
    end

  end
end



