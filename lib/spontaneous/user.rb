# encoding: UTF-8

module Spontaneous
  class User < Sequel::Model(:spontaneous_users)
    extend Forwardable

    plugin :timestamps

    one_to_one :group, :class => :'Spontaneous::AccessGroup'
    def_delegators :group, :level

    def validate
      super
      errors.add(:name, 'is required') if name.blank?
      errors.add(:email, 'is required') if email.blank?
      errors.add(:email, 'is invalid') unless email =~ /^[^@]+@.+$/
      if login.blank?
        errors.add(:login, 'is required')
      else
        errors.add(:login, 'should only contain letters, numbers & underscore') unless login =~ /^[a-zA-z0-9_]+$/
        errors.add(:login, 'should be at least 3 letters long') if login.length < 3
      end
    end

    def after_create
      super
      ensure_group!
    end

    def level=(level)
      ensure_group!
      group.level = level
      group.save
    end

    def raise_on_save_failure
      false
    end

    protected

    def ensure_group!
      if group.nil?
        self.group = AccessGroup.create(:user_id => id, :level_name => UserLevel.minimum.to_s)
      end
    end
  end
end

