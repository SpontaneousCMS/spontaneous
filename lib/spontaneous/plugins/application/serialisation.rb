# encoding: UTF-8

module Spontaneous::Plugins::Application
  module Serialisation
    module ClassMethods
      include Spontaneous::JSON
      def serialise_http(object)
        encode_json(object)
      end

      def deserialise_http(serialised_object)
        decode_json(serialised_object)
      end
    end
  end
end
