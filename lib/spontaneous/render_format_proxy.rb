# encoding: UTF-8


module Spontaneous
  class RenderFormatProxy < ProxyObject

    attr_reader :format
    attr_reader :target

    def initialize(target, format)
      @target = target
      @format = format
    end

    def render(format=nil)
      target.render(format || self.format)
    end

    def method_missing(method, *args)
      if block_given?
        target.__send__(method, *args, &Proc.new)
      else
        target.__send__(method, *args)
      end
    end
  end
end
