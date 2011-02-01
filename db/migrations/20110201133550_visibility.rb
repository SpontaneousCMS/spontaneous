# encoding: UTF-8

Sequel.migration do
  up do
    add_column :content, :assigned_visible,  :boolean, :default => true, :index => true
    add_column :content, :inherited_visible, :boolean, :default => true, :index => true
  end

  down do
    drop_column :content, :assigned_visible
    drop_column :content, :inherited_visible
  end
end




