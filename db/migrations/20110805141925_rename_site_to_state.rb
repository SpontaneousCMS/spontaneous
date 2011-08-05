# encoding: UTF-8

Sequel.migration do
  up do
    rename_table(:sites, :spontaneous_state)
  end

  down do
    rename_table(:spontaneous_state, :sites)
  end
end
