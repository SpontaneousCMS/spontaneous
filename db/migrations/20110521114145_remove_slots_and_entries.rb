# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    alter_table(:content) do
      drop_column :slot_name
      drop_column :slot_id
      add_column  :box_id, :varchar
    end
  end

  down do
    alter_table(:content) do
      add_column  :slot_name
      add_column  :slot_id
      drop_column :box_id
    end
  end
end

