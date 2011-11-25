# encoding: UTF-8

module Cutaneous
  class FirstPassRenderer < Renderer

    def template_class
      Cutaneous::PublishTemplate
    end

    def context_class
      Cutaneous::PublishContext
    end
  end
end




