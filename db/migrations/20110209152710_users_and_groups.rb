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
      varchar     :name
      varchar     :level_name, :default => 'none'
      boolean     :disabled, :default => false
      varchar     :access_selector, :default => "*"
    end


    create_table!(:spontaneous_groups_users) do
      primary_key :id
      foreign_key :user_id, :spontaneous_users
      foreign_key :group_id, :spontaneous_groups
    end

    create_table!(:spontaneous_access_keys) do
      primary_key :id
      foreign_key :user_id, :spontaneous_users, :on_delete => :cascade
      index       :user_id
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
    drop_table :spontaneous_groups_users
    drop_table :spontaneous_access_keys
  end
end


