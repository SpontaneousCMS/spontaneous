# encoding: UTF-8


module Spontaneous::Render
  module ContextBase
    include Spontaneous::Render::Helpers

    attr_reader :_format, :_target, :_locals

    def initialize(target, format, parent={})
      @_target, @_format = target, format
      _update(parent)
    end

    def show_errors?
      Spontaneous.development?
    end

    alias_method :format, :_format

    def root
      Spontaneous::Site.root
    end

    def navigation(depth = 1, &block)
      case depth
      when 0, :root
        root
      when 1, :section
        navigation_at_depth(1, &block)
      end
    end

    def navigation_at_depth(depth = 1)
      _pages_at_depth(self.page, depth).each do |p|
        yield(p, self.page.active?(p))
      end
    end

    def _pages_at_depth(origin_page, depth)
      origin_page.at_depth(depth)
    end

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
      _target.owner.pieces.first == self
    end

    def last?
      _target.owner.pieces.last == self
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
    def _update(parent)
      if parent.is_a?(Hash)
        _update_with_hash(parent)
      else
        parent.instance_variables.reject { |var| /^@_/ === var.to_s }.each do |variable|
          instance_variable_set(variable, parent.instance_variable_get(variable))
        end
        _update_with_hash(parent._locals) if parent.respond_to?(:_locals)
      end
      self
    end

    def _update_with_hash(hash)
      @_locals = hash
      hash.each do |key, val|
        singleton_class.__send__(:define_method, key) { val }
      end
    end
  end
end

