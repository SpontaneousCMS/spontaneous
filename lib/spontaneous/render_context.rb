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

    def pieces
      content
    end

    def render_content
      content.map do |c|
        c.render
      end.join("\n")
    end

    def method_missing(method, *args)
      key = method.to_sym
      if target.field?(key)
        target.fields[key].__send__(output_method)
      elsif target.slot?(key)
        context_cache[target.slots[key]]
      else
        if block_given?
          target.__send__(method, *args, &Proc.new)
        else
          target.__send__(method, *args)
        end
      end
    end

    def context_cache
      @context_cache ||= Hash.new { |hash, obj| hash[obj] = RenderContext.new(obj, format) }
    end
  end
end
