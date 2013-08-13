Sequel.migration do
  up do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      set_column_type table, :path, 'varchar(2048)'
    end
  end

  down do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      set_column_type table, :path, 'varchar(255)'
    end
  end
end

