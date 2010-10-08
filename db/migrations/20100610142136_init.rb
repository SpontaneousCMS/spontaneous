Sequel.migration do
  up do
    create_table!(:content) do
      primary_key :id
      varchar :type_id, :index => true
      text    :instance_code
      integer :depth, :default => 0

      # used for page hierarchy
      integer :parent_id, :index => true
      # used for facet hierarchy
      integer :container_id, :index => true

      text    :entry_store
      column  :field_store, 'mediumtext' # actually stores all the values, so needs some breathing room
      varchar :template_id

      varchar :label
      varchar :uid, :index => true

      varchar :slug
      varchar :path, :index => true # url path

      varchar :ancestor_path, :index => true # materialised path

    end
  end

  down do
    drop_table :content
  end
end


