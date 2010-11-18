# encoding: UTF-8


module Spontaneous::Render
  module Context

    attr_reader :format, :target

    def initialize(target, format)
      @target, @format = target, format
    end

    def template
      target.template(format)
    end
    # def render
    #   template = target.template(format)
    #   template.render(self)
    # end

    def content
      target.visible_entries
    end

    def entries
      content
    end

    def facets
      content
    end

    def render_content
      content.map do |c|
        c.render
      end.join("\n")
    end

    def method_missing(method, *args, &block)
      key = method.to_sym
      if target.field?(key)
        target.send(key, *args)
      elsif target.slot?(key)
        target.slots[key]
      else
        target.send(method, *args, &block)
      end
    end

    def context_cache
      @context_cache ||= Hash.new { |hash, obj| hash[obj] = RenderContext.new(obj, format) }
    end
  end
end

