# encoding: UTF-8

module Spontaneous::Render
  class Engine
    attr_reader :template_root
    attr_accessor :template_class
    attr_accessor :context_class

    def initialize(template_root)
      @template_root = File.expand_path(template_root)
    end

    def render_content(content, format=:html)
      context = context_class.new(content, format)
      self.render(context)
    end
  end
end

