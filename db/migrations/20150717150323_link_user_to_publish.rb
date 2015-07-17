# encoding: UTF-8

Sequel.migration do
  up do
    add_column  :revisions, :user_id, :integer
  end

  down do
    drop_column :revisions, :user_id, :integer
  end
end

