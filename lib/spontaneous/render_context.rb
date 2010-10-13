
module Spontaneous
  class RenderContext
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|object_id/ }

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
