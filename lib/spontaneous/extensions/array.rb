# encoding: UTF-8

module Spontaneous
  module Extensions
    module Renderable
      def to_renderable
        Spontaneous::Output::RenderableArray.new(self)
      end
    end

    module RenderableArray
      def render_using(renderer, *args)
        self.map { |e|
          if e.respond_to?(:render_inline_using)
            e.render_inline_using(renderer, *args)
          elsif e.respond_to?(:render_using)
            e.render_using(renderer, *args)
          elsif e.respond_to?(:render)
            e.render(*args)
          else
            e
          end
        }.join
      end

      def render(*args)
        self.map { |e|
          if e.respond_to?(:render_inline)
            e.render_inline(*args)
          elsif e.respond_to?(:render)
            e.render(*args)
          else
            e
          end
        }.join
      end

      def to_renderable
        nil
      end
    end
  end
end


class Array
  # include Spontaneous::Extensions::RenderableArray
  include Spontaneous::Extensions::Renderable
end

