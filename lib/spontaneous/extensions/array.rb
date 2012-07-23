# encoding: UTF-8

module Spontaneous
  module Extensions
    module Array
      def render_using(renderer, *args)
        self.map { |e|
          if e.respond_to?(:render_using)
            e.render_using(renderer, *args)
          elsif e.respond_to?(:render)
            e.render(*args)
          else
            e
          end
        }.join
      end

      def render(*args)
        self.map { |e| e.respond_to?(:render) ? e.render(*args) : e }.join
      end
    end
  end
end


class Array
  include Spontaneous::Extensions::Array
end


