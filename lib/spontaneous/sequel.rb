require "sequel"

Sequel.extension :inflector

require 'sequel/plugins/serialization'

Sequel::Plugins::Serialization.register_format(
  :ojson,
  lambda { |v| Yajl::Encoder.new.encode(v) },
  lambda { |v| Yajl::Parser.new(:symbolize_keys => true).parse(v)   }
)
# Sequel::Plugins::Serialization.register_format(
#   :ojson,
#   lambda { |v| Oj.dump(v) },
#   lambda { |v| Oj.load(v, symbol_keys: true)   }
# )

