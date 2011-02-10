# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    create_table!(:spontaneous_users) do
      primary_key :id
      varchar     :name
      varchar     :login, :size => 32, :index => true, :unique => true
      varchar     :email
      varchar     :salt
      varchar     :crypted_password
      boolean     :disabled, :default => false

      datetime    :last_login_at
      datetime    :created_at

      index       [:login, :disabled], :name => "enabled_login_index"
    end

    create_table!(:spontaneous_groups) do
      primary_key :id
      foreign_key :user_id, :spontaneous_users, :on_delete => :cascade # test for being a single user group is user_id.nil?
      index       :user_id
      varchar     :level_name, :default => 'none'
      boolean     :disabled, :default => false
    end

    create_table!(:spontaneous_group_access) do
      primary_key :id
      foreign_key :group_id, :spontaneous_groups, :on_delete => :cascade
      varchar     :access_rule, :default => "*"
    end

    # user :join_table in many_to_many call
    create_table!(:spontaneous_groups_users) do
      primary_key :id
      foreign_key :user_id, :spontaneous_users
      foreign_key :group_id, :spontaneous_groups
    end

    create_table!(:spontaneous_access_keys) do
      primary_key :id
      foreign_key :user_id, :spontaneous_users, :on_delete => :cascade
      index       :user_id
      # Base58.encode(OpenSSL::Random.random_bytes(32).unpack("h*").first.to_i(16)) #=> 44 chars
      char        :key_id, :size => 44, :index => true, :unique => true
      datetime    :last_access_at
      varchar     :last_access_ip
      varchar     :source_ip
      datetime    :created_at
    end
  end

  down do
    drop_table :spontaneous_users
    drop_table :spontaneous_groups
    drop_table :spontaneous_groups_access
    drop_table :spontaneous_groups_users
    drop_table :spontaneous_access_keys
  end
end


