# encoding: UTF-8

require 'yajl'
# require 'oj'

Oj.default_options = { mode: :compat } if defined?(Oj)

module Spontaneous
  module JSON
    if defined?(::Oj)
      module OjParser
        def parse(json_string)
          ::Oj.load(json_string, symbol_keys: true)
        rescue
          nil
        end

        def encode(object)
          ::Oj.dump(object)
        end
      end
    end

    if defined?(::Yajl)
      module YajlParser
        def parser
          Yajl::Parser.new(symbolize_keys: true)
        end
        def encoder
          Yajl::Encoder.new
        end

        def parse(json_string)
          parser.parse(json_string)
        rescue
          nil
        end

        def encode(object)
          encoder.encode(object)
        end
      end
    end

    extend const_get ["OjParser", "YajlParser"].detect { |m| const_defined?(m) }

    def parse_json(json_string)
      Spontaneous::JSON.parse(json_string)
    end
    alias_method :decode_json, :parse_json

    def encode_json(object)
      Spontaneous::JSON.encode(object)
    end
  end
end
