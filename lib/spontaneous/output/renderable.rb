# The Renderable class is wrapped around the targets of the render context in
# order to solve a particular problem around passing parameters/locals to
# field & content render calls from within templates.

# Say you wanted to render an image field but pass it some size parameters
# in order to insert it at a particular size. You would do this in the template
# like this:
#
#     ${ image.thumbnail(width: 50, height: 50) }
#
# this renders the image into the template using the following call stack:
#
#     context.__decode_params(context.image.thumbnail(width: 50, height: 50)).render(__format, {}, ...)
#
# The important thing to notice is that the params passed to the `thumbnail` method
# are not passed into the final render and so will not result in the image being inserted
# with the custom size params.
#
# Thie Renderable class solves this by intercepting all calls that return an object
# that responds to #render and wrapping them in a Renderable instance that maintains
# any params passed to them. So in the above method chain results gives:
#
#     context.image           #=> Renderable.new(page.image, {})
#     context.image.thumbnail #=> Renderable.new(page.image.thumbnail, {width: 50, height: 50})
#
# and so the final render call will be made to the final Renderable instance which will
# invoke page.image.thumbnail#render with the :width & :height locals it's saved from the
# original template call, equivalent to:
#
#     page.image.thumbnail.render(__format, {width: 50, height: 50}, ...)

module Spontaneous::Output
  # A convenience method that tests to see if an object is 'renderable'
  # that is it responds to #render
  # and if so wraps it in a Renderable object with the given locals
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

    def method_missing(name, *args)
      result = nil
      locals = __extract_locals__(args)

      if ::Kernel.block_given?
        # If we are passed a block then we want to make sure that any values
        # yielded from that block are wrapped in Renderable instances
        # if appropriate
        block = ::Proc.new
        result = @target.send(name, *args) do |*block_args|
          renderable_args = block_args.map { |arg| ::Spontaneous::Output::Renderable(arg, locals) }
          block.call(*renderable_args)
        end
      else
        result = ::Spontaneous::Output::Renderable(@target.send(name, *args), locals)
      end
      result
    end

    def respond_to?(method_name, include_private = false)
      @target.respond_to?(method_name, include_private) || super
    end

    alias_method :respond_to_missing?, :respond_to?

    def render(format = :html, locals = {}, parent_context = nil)
      @target.render(format, __render_locals__(locals), parent_context)
    end

    def render_using(renderer, format = :html, locals = {}, parent_context = nil)
      @target.render_using(renderer, format, __render_locals__(locals), parent_context)
    end

    def render_inline(format = :html, locals = {}, parent_context = nil)
      @target.render_inline(format, __render_locals__(locals), parent_context)
    end

    def render_inline_using(renderer, format = :html, locals = {}, parent_context = nil)
      @target.render_inline_using(renderer, format, __render_locals__(locals), parent_context)
    end

    def to_ary
      @target.to_ary
    end

    def renderable
      ::Spontaneous::Output::Renderable(@target.renderable, locals)
    end

    private

    def __render_locals__(locals)
      return @template_params if locals.nil?
      locals.merge(@template_params || {})
    end

    # This is a non-destructive version of activesupport's Array#extract_options!
    def __extract_locals__(args)
      if args.last.is_a?(::Hash)
        args.last
      else
        {}
      end
    end
  end
end
