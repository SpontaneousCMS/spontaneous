# encoding: UTF-8

module Spontaneous
  class Box
    extend Plugins

    plugin Plugins::SchemaHierarchy
    plugin Plugins::Fields
    plugin Plugins::Styles
    plugin Plugins::Render
    plugin Plugins::AllowedTypes
    plugin Plugins::Permissions

    # use underscores to protect against field name conflicts
    attr_reader :_name, :_prototype, :_owner


    def initialize(name, prototype, owner)
      @_name, @_prototype, @_owner = name.to_sym, prototype, owner
      @field_initialization = false
    end

    # TODO: use generated schema id here
    def box_id
      _name
    end

    def box_name
      _name
    end

    def label
      _name.to_s
    end

    def field_store
      _owner.box_field_store(self) || initialize_fields
    end

    # don't like this
    def initialize_fields
      field_store = nil
      if default_values = _prototype.field_defaults
        field_store = []
        default_values.each do |field_name, value|
          if self.field?(field_name)
            field = self.class.field_prototypes[field_name].to_field
            field.unprocessed_value = value
            field_store << field.to_hash
          end
        end
      end
      field_store
    end

    def field_modified!(modified_field)
      _owner.box_modified!(self)
    end

    def serialize
      {
        :box_id => box_id.to_s,
        :fields => fields.serialize
      }
    end

    def style_id
      _owner.box_style_id(_name)
    end

    def container
      _owner
    end

    def entries
      []
    end

    def style
      _prototype.style
    end


    def push(content)
      insert(-1, content)
    end

    alias_method :<<, :push

    def insert(index, content)
      _owner.insert(index, content, self)
    end

    def pieces
      @pieces ||= _owner.entries.for_box(self)
    end

    def to_hash
      {
        :title => _prototype.title,
        :id => _prototype.schema_id,
        :name => _prototype.name.to_s,
        :writable => _owner.box_writable?(_name),
        :fields => self.class.readable_fields.map { |name| field_prototypes[name].to_hash },
        :allowed_types => allowed_types.map { |type| type.instance_class.json_name }
      }
    end

    def writable?
      self._owner.box_writable?(_name)
    end

    def readable?
      self._owner.box_readable?(_name)
    end
  end

end
