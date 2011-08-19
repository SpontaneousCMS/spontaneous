# encoding: UTF-8


module Spontaneous::Render
  module Context

    attr_reader :_format, :_target

    def initialize(target, format, params={})
      @_target, @_format, @_params = target, format, params
      _update(params)
    end

    alias_method :format, :_format

    def page
      _target.page
    end

    def template
      _target.template(_format)
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
      _target.iterable
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
      _target.container.pieces.first == self
    end

    def last?
      _target.container.pieces.last == self
    end

    def render_content
      _target.map do |c|
        c.render(_format, self)
      end.join("\n")
    end

    def render(format, *args)
      _target.render(format, self, *args)
    end

    def respond_to?(method)
      super || _target.respond_to?(method)
    end

    protected

    def method_missing(method, *args)
      if block_given?
        _target.__send__(method, *args, &Proc.new)
      else
        _target.__send__(method, *args)
      end
    rescue => e
      # TODO: sensible, configurable fallback for when template calls non-existant method
      # - need line number and file that generated error
      # - logging.warn when happens
      # - an inline comment when in dev mode?
      # - some placeholder text, perhaps the name of the missing method and line no.
      logger.error(e)
      # logger.error(_target)
      # logger.error(e.backtrace.join("\\n"))
      nil
    end

    # make each key of the params hash into a method call for speed
    def _update(params)
      if params.is_a?(Hash)
        params.each do |key, val|
          singleton_class.__send__(:define_method, key) { val }
        end
      else
        params.instance_variables.reject { |var| /^@_/ === var.to_s }.each do |variable|
          # puts "setting #{variable.inspect} #{self.instance_variable_defined?(variable)}"
          instance_variable_set(variable, params.instance_variable_get(variable))
        end
      end
    end
  end
end

