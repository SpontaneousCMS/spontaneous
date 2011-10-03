# encoding: UTF-8

require 'base58'

module Spontaneous
  module Permissions

    autoload :UserLevel, "spontaneous/permissions/user_level"
    autoload :User, "spontaneous/permissions/user"
    autoload :AccessGroup, "spontaneous/permissions/access_group"
    autoload :AccessKey, "spontaneous/permissions/access_key"

    @@active_user = nil

    class << self
      # Convenience shortcut so we can do Permissions[:root]
      def [](level_name)
        UserLevel[level_name]
      end

      def root
        UserLevel.root
      end

      def has_level?(user, level)
        return true unless user
        user.level >= level
      end

      def random_string(length)
        bytes = ((length * Math.log10(58))/(8 * Math.log10(2))).ceil + 2
        string = Base58.encode(OpenSSL::Random.random_bytes(bytes).unpack("h*").first.to_i(16))
        string[0...(length)]
      end
    end
  end
end
