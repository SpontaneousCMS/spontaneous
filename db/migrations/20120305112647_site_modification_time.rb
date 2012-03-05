# encoding: UTF-8

Sequel.migration do
  up do
    add_column  :spontaneous_state, :modified_at, DateTime
  end

  down do
    drop_column :spontaneous_state, :modified_at, DateTime
  end
end
