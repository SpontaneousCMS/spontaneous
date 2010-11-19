# encoding: UTF-8


module Spontaneous::Render
  module Context

    attr_reader :format, :target

    def initialize(target, format, params={})
      @target, @format = target, format
      _update(params) if params.is_a?(Hash)
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

    protected

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

    # make each key of the params hash into a method call for speed
    def _update(params)
      params.each do |key, val|
        meta.send(:define_method, key) { val }
      end
    end
  end
end

