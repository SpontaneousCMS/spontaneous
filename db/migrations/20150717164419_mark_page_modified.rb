# encoding: UTF-8

Sequel.migration do
  up do
    [:content, :spontaneous_content_history, :spontaneous_content_archive].each do |table|
      add_column  table, :touched_at, :varchar, default: nil
    end
  end

  down do
    [:content, :spontaneous_content_history, :spontaneous_content_archive].each do |table|
      drop_column  table, :touched_at
    end
  end
end


