# encoding: UTF-8


module Spontaneous
  module Extensions
    module Object
      def meta
        @_meta ||= class << self; self; end
      end
    end
  end
end


class Object
  include Spontaneous::Extensions::Object
end


