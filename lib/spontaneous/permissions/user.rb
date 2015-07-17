# encoding: UTF-8

module Spontaneous::Permissions
  class User < Sequel::Model(:spontaneous_users)
    extend Forwardable

    plugin :timestamps

    one_to_one   :group,        class: :'Spontaneous::Permissions::AccessGroup'
    many_to_many :groups,       class: :'Spontaneous::Permissions::AccessGroup', join_table: :spontaneous_groups_users
    one_to_many  :access_keys,  class: :'Spontaneous::Permissions::AccessKey', reciprocal: :user

    set_allowed_columns(:name, :login, :email, :disabled, :password, :level)

    def_delegators :group, :level, :access_selector

    def self.login(login)
      login_dataset.call(login: login).first
    end

    def self.login_dataset
      @login_dataset ||= self.where(login: :$login).
        eager_graph(:access_keys).
        prepare(:select, :select_user_by_login)
    end

    def self.authenticate(login, clear_password, ip_address = nil)
      if (user = self[login: login, disabled: false])
        authenticator = Spontaneous::Crypt.new(clear_password, user.crypted_password)
        if authenticator.valid?
          user.upgrade_authentication(authenticator) if authenticator.outdated?
          access_key = user.logged_in!(ip_address)
          return access_key
        end
      end
      nil
    end

    def self.create(attributes = {})
      level = attributes.delete(:level) || attributes.delete("level")
      user =  super
      user.update(level: Spontaneous::Permissions[level]) if level && user
      user
    end

    def self.export(user = nil)
      users = self.order(:login).all
      users = users.reject { |u| u.level > user.level } if user
      exported = {}
      exported[:users] = users.map { |u|
        export_user(u)
      }
      base_level = user.nil? ? nil : user.level
      exported[:levels] = UserLevel.all(base_level).map { |level|
        { level: level.to_s, can_publish: level.can_publish?, is_admin: level.admin? }
      }
      exported
    end

    def self.export_user(u)
      keys = u.access_keys.map { |key|
        {last_access_at: key.last_access_at.httpdate, last_access_ip: key.last_access_ip}
      }
      { id: u.id,
        name: u.name,
        email: u.email,
        login: u.login,
        level: u.level.to_s,
        disabled: u.disabled?,
        keys: keys }
    end

    attr_accessor :password
    alias_method  :disabled?, :disabled

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

    def logged_in!(ip_address = nil)
      self.last_login_at = Time.now
      generate_access_key(ip_address)
    end

    def generate_access_key(ip_address)
      key = AccessKey.new(last_access_ip: ip_address)
      self.add_access_key(key)
      self.save
      key
    end

    def encrypt_password(clear_password)
      Spontaneous::Crypt.hash_password(clear_password)
    end

    def upgrade_authentication(auth)
      update_all crypted_password: auth.upgrade
    end

    def before_save
      self.crypted_password = encrypt_password(password) unless password.blank?
      clear_access_keys! if disabled?
      super
    end

    def clear_access_keys!
      access_keys.each { | key | key.delete }
    end

    def enabled?
      !disabled?
    end

    def disable!
      self.disabled = true
      self.save
    end

    def enable!
      self.disabled = false
      self.save
    end

    def after_create
      super
      ensure_group!
    end

    def password=(new_password)
      updating_password!
      @password = new_password
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

    def admin?
      level.admin? || false
    end

    def export
      {
        name: name,
        email: email,
        login: login,
        can_publish: can_publish?,
        developer: developer?,
        admin: admin?
      }
    end

    def serialise_http(user)
      Spontaneous.serialise_http(export)
    end

    protected

    def validate
      super
      errors.add(:name,  'is required') if name.blank?
      errors.add(:email, 'is required') if email.blank?
      errors.add(:email, 'is invalid')  unless email.blank? or email =~ /\A[^@]+@.+\z/

      validate_login
      validate_login_uniqueness
      validate_password
    end

    def validate_login
      return errors.add(:login, 'is required') if login.blank?
      errors.add(:login, 'should only contain letters, numbers & underscore') unless login =~ /\A[a-zA-Z0-9_]+\z/
      errors.add(:login, 'should be at least 3 letters long') if login.length < 3
    end

    def validate_login_uniqueness
      if (u = User[login: login]) && (u.id != id)
        errors.add(:login, "must be unique, login '#{login}' already exists")
      end
    end

    def validate_password
      if new? || updating_password?
        if password.blank?
          errors.add(:password, 'is required')
        elsif password.length < 8
          errors.add(:password, 'should be at least 6 characters long')
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
        self.group = AccessGroup.create(user_id: id, name: "_#{name}_", level_name: UserLevel.none.to_s)
      end
    end
  end
end

