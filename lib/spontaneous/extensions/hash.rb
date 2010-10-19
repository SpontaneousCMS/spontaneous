
module Spontaneous
  module Extensions
    module Hash
      def to_json
        Yajl::Encoder.new.encode(self)
      end
    end
  end
end


class Hash
  include Spontaneous::Extensions::Hash
end

