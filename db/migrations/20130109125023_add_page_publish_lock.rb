Sequel.migration do
  up do
    create_table(:spontaneous_page_lock, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id

      Integer  :page_id,    :index => true
      Integer  :content_id, :index => true
      String   :field_id
      DateTime :created_at
      String   :description
    end
  end

  down do
    drop_table :spontaneous_page_lock
  end
end
