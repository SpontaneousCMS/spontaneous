
module Spontaneous
  class RenderFormatProxy
    instance_methods.each { |m| undef_method m unless m =~ /^__|instance_eval|object_id/ }

    attr_reader :format
    attr_reader :target

    def initialize(target, format)
      @target = target
      @format = format
    end

    def render(format=nil)
      target.render(format || self.format)
    end

    def method_missing(method, *args, &block)
      target.send(method, *args, &block)
    end
  end
end
