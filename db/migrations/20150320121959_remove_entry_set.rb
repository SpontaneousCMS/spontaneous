# encoding: UTF-8

require 'logger'

Sequel.migration do
  up do

    [:spontaneous_content_history, :spontaneous_content_archive].each do |table|
      alter_table(table) do
        add_index [:id, :revision], ignore_errors: true
      end
    end

    [:content, :spontaneous_content_history, :spontaneous_content_archive].each do |table|
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
