# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme

    add_column :content, :created_at,         DateTime
    add_column :content, :modified_at,        DateTime

    add_column :content, :first_published_at, DateTime
    add_column :content, :last_published_at,  DateTime

    add_column :content, :first_published_revision,  Integer

    # keeps track of publication dates
    create_table(:revisions, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      integer     :revision
      timestamp   :published_at
    end

    # keeps track of all pages changed by a set of actions
    create_table(:changes, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      varchar     :title
      timestamp   :created_at
      text        :modified_list
    end
  end

  down do
    drop_column :artists, :first_published_at
    drop_column :content, :created_at,         DateTime
    drop_column :content, :modified_at,        DateTime
    drop_column :content, :first_published_at, DateTime
    drop_column :content, :last_published_at,  DateTime
    drop_column :content, :first_published_revision,  Integer
    drop_table :revisions
    drop_table :changes
  end
end



