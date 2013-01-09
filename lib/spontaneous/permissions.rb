# encoding: UTF-8

require 'base58'
require 'securerandom'

module Spontaneous
  module Permissions

    autoload :UserLevel, "spontaneous/permissions/user_level"
    autoload :User, "spontaneous/permissions/user"
    autoload :AccessGroup, "spontaneous/permissions/access_group"
    autoload :AccessKey, "spontaneous/permissions/access_key"

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
        SecureRandom.urlsafe_base64(length)[0...(length)]
      end
    end
  end
end
