
module Spontaneous::Output
  def self.Renderable(obj, locals)
    if obj.respond_to?(:render)
      Renderable.new(obj, locals)
    else
      obj
    end
  end

  class Renderable < BasicObject

    def initialize(target, template_params = {})
      @target, @template_params = target, (template_params || {})
    end

    def method_missing(name, *args, &block)
      result = nil
      locals = extract_locals(args)

      if block
        result = @target.send(name, *args) do |*aa|
          r = aa.map { |a| ::Spontaneous::Output::Renderable(a, locals) }
          block.call(*r)
        end
      else
        obj = @target.send(name, *args)
        result = ::Spontaneous::Output::Renderable(obj, locals)
      end
      result
    end

    def respond_to?(method_name, include_private = false)
      @target.respond_to?(method_name, include_private) || super
    end

    alias_method :respond_to_missing?, :respond_to?

    def render(format = :html, params = {}, parent_context = nil)
      @target.render(format, render_params(params), parent_context)
    end

    def render_using(renderer, format = :html, params = {}, parent_context = nil)
      @target.render_using(renderer, format, render_params(params), parent_context)
    end

    protected

    def render_params(params)
      # $stdout.puts [:render_params, params, @template_params].inspect
      return @template_params if params.nil?
      params.merge(@template_params || {})
      # if params.respond_to?(:__update_context)
      #   params.__update_context(@template_params || {})
      # else
      # end
    end

    def __renderable(obj, locals)
    end

    def extract_locals(args)
      if args.last.is_a?(::Hash)
        args.last
      else
        {}
      end
    end
  end
end
