# encoding: UTF-8

Sequel.migration do
  up do
    add_column :sites, :pending_revision,  Integer
  end

  down do
    drop_column :sites, :pending_revision
  end
end




