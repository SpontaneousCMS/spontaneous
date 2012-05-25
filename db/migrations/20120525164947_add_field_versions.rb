Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    create_table(:spontaneous_field_versions, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id

      case adapter_scheme
      when :mysql, :mysql2
        column  :value, 'mediumtext'
      else
        text    :value
      end

      Integer  :content_id
      String   :field_sid
      DateTime :created_at
      Integer  :version
      Integer  :user_id

      index [:content_id, :field_sid]
    end
  end

  down do
    drop_table :spontaneous_field_versions
  end
end
