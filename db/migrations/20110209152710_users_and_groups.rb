# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    create_table(:spontaneous_users, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      varchar     :name
      varchar     :login, :size => 32, :index => true, :unique => true
      varchar     :email
      varchar     :salt
      varchar     :crypted_password
      boolean     :disabled, :default => false

      timestamp   :last_login_at, :default => nil, :null => true
      timestamp   :created_at

      index       [:login, :disabled], :name => "enabled_login_index"
    end

    create_table(:spontaneous_groups, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      foreign_key :user_id, :spontaneous_users, :key => :id, :on_delete => :cascade # test for being a single user group is user_id.nil?
      index       :user_id
      varchar     :name
      varchar     :level_name, :default => 'none'
      boolean     :disabled, :default => false
      varchar     :access_selector, :default => "*"
    end


    create_table(:spontaneous_groups_users, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      foreign_key :user_id, :spontaneous_users, :key => :id, :on_delete => :cascade
      foreign_key :group_id, :spontaneous_groups, :key => :id, :on_delete => :cascade
    end

    create_table(:spontaneous_access_keys, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      foreign_key :user_id, :spontaneous_users, :key => :id, :on_delete => :cascade
      index       :user_id
      char        :key_id, :size => 44, :index => true, :unique => true
      timestamp   :last_access_at
      varchar     :last_access_ip
      varchar     :source_ip
      timestamp   :created_at
    end
  end

  down do
    drop_table :spontaneous_access_keys
    drop_table :spontaneous_groups_users
    drop_table :spontaneous_groups
    drop_table :spontaneous_users
  end
end


