# encoding: UTF-8

module Cutaneous
  class FirstPassRenderer < Renderer

    def template_class
      Cutaneous::FirstPassParser
    end

    def context_class
      Cutaneous::PublishContext
    end
  end
end




