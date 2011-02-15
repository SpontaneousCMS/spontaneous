# encoding: UTF-8

module Spontaneous
  class Box
    extend Plugins

    plugin Plugins::SchemaHierarchy
    plugin Plugins::Fields

    # use underscores to protect against field name conflicts
    attr_reader :_name, :_prototype, :_owner

    def initialize(name, prototype, owner)
      @_name, @_prototype, @_owner = name.to_sym, prototype, owner
    end

    def box_name
      _prototype.name
    end

    def field_store
      _owner.box_field_store(_name)
    end

    def field_modified!(modified_field)
      _owner.box_modified!(self)
    end

    def serialize
     {
       :box_id => _name,
       :fields => fields.serialize
     }
    end
  end
end
