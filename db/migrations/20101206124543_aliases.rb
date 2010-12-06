# encoding: UTF-8

Sequel.migration do
  up do
    add_column :content, :target_id,  Integer
  end

  down do
    drop_column :content, :target_id
  end
end





