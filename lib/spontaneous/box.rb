# encoding: UTF-8

module Spontaneous
  class Box
    extend Plugins
    include Enumerable

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

    alias_method :id, :box_id

    def box_name
      _name
    end

    def label
      _name.to_s
    end

    # needed by Render::Context
    def box?(box_name)
      false
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
      @modified = true
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

    def page
      container.page
    end

    def depth
      container.depth
    end

    # def style
    #   _prototype.style
    # end


    def push(content)
      insert(-1, content)
    end

    alias_method :<<, :push

    def insert(index, content)
      @modified = true
      _owner.insert(index, content, self)
    end

    def set_position(entry, new_position)
      @modified = true
      piece = pieces[new_position]
      new_position = container.entries.index(piece)
      container.entries.set_position(entry, new_position)
    end

    def modified?
      @modified
    end

    def pieces
      @pieces ||= _owner.entries.for_box(self)
    end

    alias_method :entries, :pieces

    def each
      pieces.each do |piece|
        yield piece if block_given?
      end
    end

    def last
      pieces.last
    end

    def _content
      pieces
    end

    def to_hash
      {
        :id => _prototype.schema_id,
        :fields => self.class.readable_fields.map { |name| field_prototypes[name].to_hash },
        :entries => pieces.map { |p| p.to_hash }
      }
    end

    def writable?
      self._owner.box_writable?(_name)
    end

    def readable?
      self._owner.box_readable?(_name)
    end

    def start_inline_edit_marker
      "spontaneous:previewedit:start:box id:#{id}"
    end

    def end_inline_edit_marker
      "spontaneous:previewedit:end:box id:#{id}"
    end
  end

end
