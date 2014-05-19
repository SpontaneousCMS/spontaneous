# encoding: UTF-8

Sequel.migration do
  up do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      alter_table table do
        add_column :content_hash_changed_at, :timestamp
      end
      self[table].update(content_hash_changed_at: :modified_at)
    end
  end

  down do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      alter_table table do
        drop_column :content_hash_changed_at
      end
    end
  end
end
