Sequel.migration do
  up do
    rename_table :spontaneous_content_revisions, :spontaneous_content_history
  end

  down do
    rename_table :spontaneous_content_history, :spontaneous_content_revisions
  end
end
