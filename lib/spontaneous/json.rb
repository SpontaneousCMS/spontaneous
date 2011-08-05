# encoding: UTF-8

module Spontaneous
  module JSON
    module ModuleMethods
      def parser
        Yajl::Parser.new(:symbolize_keys => true)
      end
      def encoder
        Yajl::Encoder.new
      end

      def parse(json_string)
        parser.parse(json_string)
      end

      def encode(object)
        encoder.encode(object)
      end
    end

    extend ModuleMethods

    def parse_json(json_string)
      Spontaneous::JSON.parse(json_string)
    end
    alias_method :decode_json, :parse_json

    def encode_json(object)
      Spontaneous::JSON.encode(object)
    end
  end
end
