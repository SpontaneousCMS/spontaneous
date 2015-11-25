# encoding: UTF-8

Sequel.migration do
  up do
    add_index :spontaneous_content_archive, [:revision]
  end

  down do
    drop_index :spontaneous_content_archive, [:revision]
  end
end


