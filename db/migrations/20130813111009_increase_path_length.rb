Sequel.migration do

  up do
    length = case self.adapter_scheme
    when :mysql, :mysql2
      # http://stackoverflow.com/questions/1814532/1071-specified-key-was-too-long-max-key-length-is-767-bytes/1814594#1814594
      # reasons to move away from mysql...
      255
    else
      2048
    end

    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      set_column_type table, :path, "varchar(#{length})"
    end
  end

  down do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      set_column_type table, :path, 'varchar(255)'
    end
  end
end
