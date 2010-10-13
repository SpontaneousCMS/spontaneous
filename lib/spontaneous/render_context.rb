
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
      template = target.style.template(format)
      template.render(binding)
    end

    def content
      target.visible_entries.map { |e| RenderFormatProxy.new(e, format) }
    end

    def method_missing(method, *args, &block)
      # key = method.to_s.gsub(/\\?$/,'').to_sym
      key = method.to_sym
      if target.field?(key)
        target.fields[key].send(output_method)
      else
        target.send(method, *args, &block)
      end
    end
  end
end
