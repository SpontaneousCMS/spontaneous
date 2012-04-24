# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    alter_table(:content) do
      case adapter_scheme
      when :mysql, :mysql2
        add_column  :serialized_modifications, 'mediumtext'
      else
        add_column  :serialized_modifications, :text
      end
    end
  end

  down do
    alter_table(:content) do
      drop_column :serialized_modifications
    end
  end
end
