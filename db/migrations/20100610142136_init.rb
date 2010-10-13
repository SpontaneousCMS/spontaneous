Sequel.migration do
  up do
    create_table!(:content) do
      primary_key :id
      varchar :type_id, :index => true
      text    :instance_code
      integer :depth, :default => 0

      # used for Page tree structure
      # #pageonly
      integer :parent_id, :index => true
      varchar :ancestor_path, :index => true # materialised path

      # used to get the parent Content item (Page or Facet)
      integer :container_id, :index => true

      # used to find all content for a Page
      integer :page_id, :index => true

      # content stores
      text    :entry_store
      column  :field_store, 'mediumtext' # actually stores all the values, so needs some breathing room

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
  end

  down do
    drop_table :content
  end
end


