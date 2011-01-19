# encoding: UTF-8


module Spontaneous
  class RenderContext < ProxyObject

    def initialize(target, format)
      @target = target
      @format = format
    end

    def target
      @target
    end

    def format
      @format
    end

    def output_method
      @output_method ||= "to_#{format}".to_sym
    end

    def render
      template = target.template(format)
      template.render(self)
    end

    def content
      target.visible_entries.map { |e| context_cache[e] }
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
        target.fields[key].__send__(output_method)
      elsif target.slot?(key)
        context_cache[target.slots[key]]
      else
        target.__send__(method, *args, &block)
      end
    end

    def context_cache
      @context_cache ||= Hash.new { |hash, obj| hash[obj] = RenderContext.new(obj, format) }
    end
  end
end
