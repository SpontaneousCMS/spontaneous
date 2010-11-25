# encoding: UTF-8


module Spontaneous::Render
  module Context

    attr_reader :format, :target

    def initialize(target, format, params={})
      @target, @format, @params = target, format, params
      _update(params) if params.is_a?(Hash)
    end

    def template
      target.template(format)
    end

    def each
      content.each { |c| yield(c) } if block_given?
    end

    def each_with_index
      content.each_with_index { |c, i| yield(c, i) } if block_given?
    end

    def map
      content.map { |c| yield(c) } if block_given?
    end

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

    def render(format, *args)
      target.render(format, *args)
    end

    def respond_to?(method)
      super || target.respond_to?(method)
    end

    protected

    def method_missing(method, *args, &block)
      key = method.to_sym
      if target.field?(key)
        target.send(key, *args)
      elsif target.slot?(key)
        self.class.new(target.slots[key], format, @params)
      else
        target.send(method, *args, &block)
      end
    rescue
      # TODO: sensible, configurable fallback for when template calls non-existant method
      # - logging.warn when happens
      # - an inline comment when in dev mode?
      # - some placeholder text, perhaps the name of the missing method and line no.
      nil
    end

    # make each key of the params hash into a method call for speed
    def _update(params)
      params.each do |key, val|
        meta.send(:define_method, key) { val }
      end
    end
  end
end

