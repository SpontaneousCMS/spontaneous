# encoding: UTF-8

Sequel.migration do
  up do
    add_index :content, :target_id
  end

  down do
    drop_index :content, :target_id
  end
end
