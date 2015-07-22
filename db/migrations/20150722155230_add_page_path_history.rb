# encoding: UTF-8

Sequel.migration do
  up do
    options = {
      engine: "INNODB",
      charset: "UTF8",
      collate: "utf8_general_ci"
    }

    create_table(:spontaneous_page_path_history, options) do
      primary_key :id

      String   :path, size: 2048, index: true
      Integer  :page_id, index: true
      DateTime :created_at
      Integer  :revision
    end
  end

  down do
    drop_table :spontaneous_page_path_history
  end
end

