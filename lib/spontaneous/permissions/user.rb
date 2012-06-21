# encoding: UTF-8

module Spontaneous::Permissions
  class User < Sequel::Model(:spontaneous_users)
    extend Forwardable

    plugin :timestamps

    one_to_one   :group,        :class => :'Spontaneous::Permissions::AccessGroup'
    many_to_many :groups,       :class => :'Spontaneous::Permissions::AccessGroup', :join_table => :spontaneous_groups_users
    one_to_many  :access_keys,  :class => :'Spontaneous::Permissions::AccessKey'

    set_restricted_columns(:crypted_password)

    def_delegators :group, :level, :access_selector

    def self.encrypt_password(clear_password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{clear_password}--")
    end

    def self.authenticate(login, clear_password)
      if user = self[:login => login, :disabled => false]
        crypted_password = user.encrypt_password(clear_password)
        if crypted_password == user.crypted_password
          access_key = user.logged_in!
          return access_key
        end
      end
      nil
    end

    attr_accessor :password, :password_confirmation

    ##
    # Find the highest access level available from all the groups we
    # belong to
    # TODO: actually match the content against the memberships
    def level_for(content)
      memberships.map { |m| m.level_for(content) }.sort.last
    end

    def last_access_at
      access_keys.map(&:last_access_at).sort.last
    end

    def logged_in!
      self.last_login_at = Time.now
      generate_access_key
    end

    def generate_access_key
      key = AccessKey.new
      self.add_access_key(key)
      self.save
      key
    end

    def encrypt_password(clear_password)
      self.class.encrypt_password(clear_password, salt)
    end

    def before_save
      self.salt = Spontaneous::Permissions.random_string(32) if salt.blank?
      self.crypted_password = encrypt_password(password) unless password.blank?
      if self.disabled
        access_keys.each { | key | key.delete }
      end
      super
    end

    def after_create
      super
      ensure_group!
    end

    def password=(new_password)
      updating_password!
      @password = new_password
    end

    def password_confirmation=(new_password)
      updating_password!
      @password_confirmation = new_password
    end

    def level=(level)
      ensure_group!
      group.level = level
      group.save
    end

    def raise_on_save_failure
      false
    end

    def memberships
      groups.push(group)
    end

    def developer?
      level.developer? || false
    end

    def can_publish?
      level.can_publish? || false
    end

    def export
      {
        :name => name,
        :email => email,
        :login => login,
        :can_publish => can_publish?,
        :developer => !!developer?
      }
    end

    def serialise_http(user)
      Spontaneous.serialise_http(export)
    end

    protected

    def validate
      super
      errors.add(:name, 'is required') if name.blank?
      errors.add(:email, 'is required') if email.blank?
      errors.add(:email, 'is invalid') unless email =~ /^[^@]+@.+$/

      if login.blank?
        errors.add(:login, 'is required')
      else
        errors.add(:login, 'should only contain letters, numbers & underscore') unless login =~ /^[a-zA-Z0-9_]+$/
        errors.add(:login, 'should be at least 3 letters long') if login.length < 3
      end

      if errors[:login].empty? && new?
        if User[:login => login]
          errors.add(:login, "must be unique, login '#{login}' already exists")
        end
      end

      if new? || updating_password?
        if password.blank?
          errors.add(:password, 'is required')
        elsif password_confirmation.blank?
          errors.add(:password_confirmation, 'is required')
        else
          if password != password_confirmation
            errors.add(:password_confirmation, 'should match the password')
          else
            if password.length < 6
              errors.add(:password, 'is too short. It should be at least 6 characters')
            end
          end
        end
      end
    end


    def updating_password!
      @_updating_password = true
    end

    def updating_password?
      @_updating_password
    end

    def ensure_group!
      if group.nil?
        self.group = AccessGroup.create(:user_id => id, :name => "_#{name}_", :level_name => UserLevel.none.to_s)
      end
    end
  end
end

