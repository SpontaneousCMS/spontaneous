# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    alter_table(:content) do
      # content stores
      case adapter_scheme
      when :mysql, :mysql2
        add_column  :box_store, 'mediumtext'
      else
        add_column  :box_store, :text
      end
    end
  end

  down do
    alter_table(:content) do
      drop_column :box_store
    end
  end
end



