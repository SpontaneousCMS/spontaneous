# encoding: UTF-8

require 'logger'

Sequel.migration do
  up do

    [:spontaneous_content_history, :spontaneous_content_archive].each do |table|
      indexes = self.indexes(table)
      if indexes.values.map { |index| index[:columns] }.any? { |cols| cols == [:id, :revision] }
        puts "Skipping id, revision index on table #{table}..."
        next
      end
      alter_table(table) do
        add_index [:id, :revision], ignore_errors: true
      end
    end

    [:content, :spontaneous_content_history, :spontaneous_content_archive].each do |table|
      existing_columns = self[table].columns
      if (existing_columns & [:box_position, :layout_sid]).length > 0
        puts "Skipping migration for table #{table}..."
        next
      end
      alter_table(table) do
        add_column :box_position, :integer
        add_column :layout_sid,   :varchar
        add_index [:box_sid, :box_position] if table == :content
      end

      # self.logger = Logger.new $stdout
      content = self[table]

      position, total = 0, content.count

      puts 'Migrating %d `%s` items to new box model' % [total, table] if Spontaneous.mode == :console

      content.each do |row|
        if (store = Spontaneous::JSON.parse(row[:entry_store]))
          store.each_with_index do |data, i|
            id = data[0]
            ds = content.where(id: id, revision: row[:revision])
            if data.length == 2 #page
              ds.update(layout_sid: Sequel.expr(:style_sid))
              ds.update(style_sid: data[1], box_position: i)
            else
              ds.update(box_position: i)
            end
          end
        end
        print "    #{table} => % #{total.to_s.length}d/%#{total.to_s.length}d complete\r" % [position+=1, total] if Spontaneous.mode == :console
      end
      puts "\n    #{table} Done" if Spontaneous.mode == :console

      alter_table(table) do
        drop_column :entry_store rescue nil
      end
    end
    # recreate the published table from the history rather than run the
    # migration again on it.
    if (published_revision = self[:spontaneous_state].get(:published_revision))
      require 'spontaneous/publishing/revision.rb'
      published_revision_table = Spontaneous::DataMapper::ContentTable.revision_table(:content, published_revision)
      drop_table(published_revision_table)
      Spontaneous::Publishing.create_content_table(self, :content, published_revision_table)
      source_ds = self[:spontaneous_content_history].where(revision: published_revision)
      run("INSERT INTO #{literal(published_revision_table)} #{source_ds.select_sql}")
    end

    # drop all the indexes on the archive because we don't need them
    table = :spontaneous_content_archive
    indexes(table).each do |index_name, index|
      alter_table(table) do
        drop_index index[:columns], name: index_name
      end
    end
    # force a full publish
    self[:spontaneous_state].update(must_publish_all: true)
  end

  down do
    adapter_scheme =  self.adapter_scheme

    [:spontaneous_content_history, :spontaneous_content_archive].each do |table|
      alter_table(table) do
        drop_index [:id, :revision]
      end
    end

    [:content, :spontaneous_content_history, :spontaneous_content_archive].each do |table|
      alter_table(table) do
        case adapter_scheme
        when :mysql, :mysql2
          add_column :entry_store, 'mediumtext'
        else
          add_column :entry_store, :text
        end
      end
      puts "MUST GO BACK"
      alter_table(table) do
        drop_index [:box_sid, :box_position] if table == :content
        drop_column :box_position
        drop_column :layout_sid
      end
    end
  end
end
