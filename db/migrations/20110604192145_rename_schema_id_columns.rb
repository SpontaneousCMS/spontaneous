# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    alter_table(:content) do
      rename_column :type_id, :type_sid
      rename_column :style_id, :style_sid
      rename_column :box_id, :box_sid
    end
  end

  down do
    alter_table(:content) do
      rename_column :type_sid, :type_id
      rename_column :style_sid, :style_id
      rename_column :box_sid, :box_id
    end
  end
end


