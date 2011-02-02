# encoding: UTF-8

Sequel.migration do
  up do
    alter_table(:content) do
      add_column :visible,  :boolean, :default => true
      # keeps track of the id of the parent item that is giving us our invisible status
      add_column :visibility_origin, :integer
      # a 'materialized path' for the complete content path
      add_column :content_path, String

      add_index :visible
      add_index :content_path
    end
  end

  down do
    alter_table(:content) do
      drop_index :visible
      drop_index :content_path
      drop_column :visible
      drop_column :visibility_origin
      drop_column :content_path
    end
  end
end

