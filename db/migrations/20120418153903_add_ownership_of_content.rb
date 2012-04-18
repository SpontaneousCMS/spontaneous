# encoding: UTF-8

Sequel.migration do
  up do
    alter_table :content do
      add_foreign_key :created_by_id, :spontaneous_users, :key => :id, :on_delete => :set_null
    end
  end

  down do
    drop_column :content, :created_by_id
  end
end

