# encoding: UTF-8

module Spontaneous::Permissions
  class AccessKey < Sequel::Model(:spontaneous_access_keys)
    plugin :timestamps
    many_to_one :user, :class => :'Spontaneous::Permissions::User'

    def self.authenticate(key_id)
      if key = self.for_id(key_id)
        key.access!
        return key
      end
      nil
    end

    def self.valid?(key_id, user)
      return true if (key = self.for_id(key_id)) and key.user == user
      false
    end

    def self.for_id(key_id)
      self[:key_id => key_id]
    end

    def before_create
      self.key_id = Spontaneous::Permissions.random_string(44)
      self.last_access_at = Time.now
      super
    end

    def access!
      self.update(:last_access_at => Time.now)
    end
  end
end
