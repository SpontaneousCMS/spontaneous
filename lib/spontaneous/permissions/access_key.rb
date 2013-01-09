# encoding: UTF-8

module Spontaneous::Permissions
  class AccessKey < Sequel::Model(:spontaneous_access_keys)
    plugin :timestamps
    many_to_one :user, :class => :'Spontaneous::Permissions::User', :reciprocal => :access_keys

    def self.authenticate(key_id, ip_address = nil)
      if key = self.for_id(key_id)
        key.access!(ip_address)
        return key
      end
      nil
    end

    def self.valid?(key_id, user)
      return true if (key = self.for_id(key_id)) && (key.user == user) && (key.user.enabled?)
      false
    end

    def self.for_id(key_id)
      key_dataset.call(:key_id => key_id).first
    end

    def self.key_dataset
      @key_dataset ||= self.where(:key_id => :$key_id).
        eager_graph(:user).
        prepare(:select, :select_access_key_by_key)
    end

    def before_create
      self.key_id = Spontaneous::Permissions.random_string(44)
      self.last_access_at = Time.now
      super
    end

    def access!(ip_address = nil)
      self.update(:last_access_at => Time.now, :last_access_ip => ip_address)
    end
  end
end
