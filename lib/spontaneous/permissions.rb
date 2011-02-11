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

      def with_user(user)
        self.active_user = user
        yield if block_given?
      ensure
        self.active_user = nil
      end

      def active_user
        Thread.current[:_permissions_active_user]
      end

      def active_user=(user)
        Thread.current[:_permissions_active_user] = user
      end

      protected(:active_user=)

      def random_string(length)
        # can't be bothered to work out the real rules behind this
        bytes = (length.to_f / 1.375).ceil + 2
        string = Base58.encode(OpenSSL::Random.random_bytes(bytes).unpack("h*").first.to_i(16)) #=> 44 chars
        string[0...(length)]
      end

    end
  end
end
