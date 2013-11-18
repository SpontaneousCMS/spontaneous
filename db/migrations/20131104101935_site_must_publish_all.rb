# encoding: UTF-8

Sequel.migration do
  up do
    add_column  :spontaneous_state, :must_publish_all, TrueClass, default: true
    # although we want new state instances to set the force publish all flag it
    # would be wrong for existing sites to have this flag set
    self[:spontaneous_state].update(must_publish_all: false)
  end

  down do
    drop_column :spontaneous_state, :must_publish_all, TrueClass
  end
end
