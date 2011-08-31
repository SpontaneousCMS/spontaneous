# encoding: UTF-8

module Spontaneous
  module Extensions
    module Array
      def render(*args)
        self.map { |e| e.respond_to?(:render) ? e.render(*args) : nil }.join
      end
    end
  end
end


class Array
  include Spontaneous::Extensions::Array
end


