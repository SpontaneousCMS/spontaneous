# encoding: UTF-8


module Spontaneous
  module Extensions
    module Object
      def blank?
        respond_to?(:empty?) ? empty? : !self
      end

      def meta
        @_meta ||= class << self; self; end
      end
    end
  end
end


class Object
  include Spontaneous::Extensions::Object
end

