# encoding: UTF-8

module Spontaneous
  module Extensions
    module Array
      def render(format = :html)
        self.map { |e| e.respond_to?(:render) ? e.render(format) : nil }.join
      end
    end
  end
end


class Array
  include Spontaneous::Extensions::Array
end


