# encoding: UTF-8

Sequel.migration do
  no_transaction
  up do
    [:content, :spontaneous_content_archive, :spontaneous_content_history].each do |table|
      begin
        alter_table table do
          add_column :content_hash_changed_at, :timestamp
        end
      rescue ::Sequel::DatabaseError => e
        # because syncing ignores the content_archive table
        # if we run this migration, then sync, then re-run it
        # (in the case where the production db is behind the dev db)
        # this one table will throw an error
        raise unless table == :spontaneous_content_archive
      end
      transaction do
        self[table].update(content_hash_changed_at: :modified_at)
      end
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
