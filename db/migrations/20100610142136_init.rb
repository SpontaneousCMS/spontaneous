# encoding: UTF-8

Sequel.migration do
  up do
    adapter_scheme =  self.adapter_scheme
    create_table(:content, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      varchar :type_id, :index => true
      text    :instance_code
      integer :depth, :default => 0

      # used for Page tree structure
      # #pageonly
      integer :parent_id, :index => true
      varchar :ancestor_path, :index => true # materialised path

      # used to get the parent Content item (Page or Piece)
      integer :container_id, :index => true

      # used to find all content for a Page
      integer :page_id, :index => true

      # content stores
      case adapter_scheme
      when :mysql, :mysql2
        column  :field_store, 'mediumtext'
        column  :entry_store, 'mediumtext'
      else
        text    :field_store
        text    :entry_store
      end

      # used to store the template assigned to a page
      # #pageonly
      varchar :style_id

      varchar :label
      varchar :slot_name
      varchar :slot_id

      # URL path fields
      # #pageonly
      varchar :slug
      varchar :path, :index => true # url path

      # For quick path-independent page lookups
      # #pageonly
      varchar :uid, :index => true


    end

    create_table(:sites, :engine => "INNODB", :charset => "UTF8", :collate => "utf8_general_ci") do
      primary_key :id
      integer :revision, :default => 1
      integer :published_revision, :default => 0
    end
  end

  down do
    drop_table :content
    drop_table :sites
  end
end


