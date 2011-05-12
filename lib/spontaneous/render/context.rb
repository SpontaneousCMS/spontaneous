# encoding: UTF-8


module Spontaneous::Render
  module Context

    attr_reader :format, :target

    def initialize(target, format, params={})
      @target, @format, @params = target, format, params
      _update(params) if params.is_a?(Hash)
    end

    def page
      target.page
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
      target.iterable
    end

    def pieces
      content
    end

    def first
      content.first
    end

    def last
      content.last
    end

    def first?
      target.container.pieces.first == self
    end

    def last?
      target.container.pieces.last == self
    end

    def render_content
      target.map do |c|
        c.render(format)
      end.join("\n")
    end

    def render(format, *args)
      target.render(format, *args)
    end

    def respond_to?(method)
      super || target.respond_to?(method)
    end

    protected

    def method_missing(method, *args)
      if block_given?
        target.__send__(method, *args, &Proc.new)
      else
        target.__send__(method, *args)
      end
    rescue => e
      # TODO: sensible, configurable fallback for when template calls non-existant method
      # - need line number and file that generated error
      # - logging.warn when happens
      # - an inline comment when in dev mode?
      # - some placeholder text, perhaps the name of the missing method and line no.
      logger.error(e)
      # logger.error(target)
      # logger.error(e.backtrace.join("\\n"))
      nil
    end

    # make each key of the params hash into a method call for speed
    def _update(params)
      params.each do |key, val|
        meta.__send__(:define_method, key) { val }
      end
    end
  end
end

