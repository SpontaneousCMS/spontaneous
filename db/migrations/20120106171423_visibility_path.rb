# encoding: UTF-8

Sequel.migration do
  up do
    alter_table(:content) do
      drop_index :content_path
      rename_column :content_path, :visibility_path
      add_index :visibility_path
    end
  end

  down do
    alter_table(:content) do
      drop_index :visibility_path
      rename_column :visibility_path, :content_path
      add_index :content_path
    end
  end
end
