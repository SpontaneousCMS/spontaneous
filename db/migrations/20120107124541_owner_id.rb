# encoding: UTF-8

Sequel.migration do
  up do
    alter_table(:content) do
      drop_index :container_id
      rename_column :container_id, :owner_id
      add_index :owner_id
    end
  end

  down do
    alter_table(:content) do
      drop_index :owner_id
      rename_column :owner_id, :container_id
      add_index :container_id
    end
  end
end
