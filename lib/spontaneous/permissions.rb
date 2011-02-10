# encoding: UTF-8

require 'base58'

module Spontaneous
  module Permissions

    autoload :UserLevel, "spontaneous/permissions/user_level"
    autoload :User, "spontaneous/permissions/user"
    autoload :AccessGroup, "spontaneous/permissions/access_group"
    autoload :AccessKey, "spontaneous/permissions/access_key"

    def self.random_string(length)
      # can't be bothered to work out the real rules behind this
      bytes = (length.to_f / 1.375).ceil + 2
      string = Base58.encode(OpenSSL::Random.random_bytes(bytes).unpack("h*").first.to_i(16)) #=> 44 chars
      string[0...(length)]
    end
  end
end
