
module Spontaneous
  module Extensions
    module JSON
      def to_json
        Yajl::Encoder.new.encode(self)
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


