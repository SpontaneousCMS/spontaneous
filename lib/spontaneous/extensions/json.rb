# encoding: UTF-8


module Spontaneous
  module Extensions
    module JSON
      def to_json
        Spontaneous::JSON.encode(self)
      end
      def serialise_http(user)
        Spontaneous.serialise_http(self)
      end
    end
  end
end


class Hash
  include Spontaneous::Extensions::JSON
end

class Array
  include Spontaneous::Extensions::JSON
end


