# encoding: UTF-8

Sequel.migration do
  up do
    add_column :content, :visible,  :boolean, :default => true, :index => true
    # keeps track of the id of the parent item that is giving us our invisible status
    add_column :content, :inherited_visible, :integer
  end

  down do
    drop_column :content, :visible
    drop_column :content, :inherited_visible
  end
end




