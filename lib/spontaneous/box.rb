# encoding: UTF-8

module Spontaneous
  class Box
    extend Plugins
    include Enumerable

    plugin Plugins::SchemaHierarchy
    plugin Plugins::Fields
    plugin Plugins::Styles
    plugin Plugins::Serialisation
    plugin Plugins::Render
    plugin Plugins::AllowedTypes
    plugin Plugins::Permissions
    plugin Plugins::Media

    # use underscores to protect against field name conflicts
    attr_reader :_name, :_prototype, :_owner
    attr_accessor :template_params


    def initialize(name, prototype, owner)
      @_name, @_prototype, @_owner = name.to_sym, prototype, owner
      @field_initialization = false
    end


    def self.page?
      false
    end

    def self.is_box?
      true
    end

    def self.schema_id
      Spontaneous.schema.schema_id(self)
    end

    def self.schema_name
      "type//#{self.name}"
    end


    def self.supertype
      if self == Spontaneous::Box
        nil
      else
        superclass
      end
    end

    def self.supertype?
      !supertype.nil? #&& supertype.respond_to?(:field_prototypes)
    end

    # def self.owner_sid
    #   nil
    # end

    def page?
      false
    end

    alias_method :is_page?, :page?

    def is_box?
      true
    end

    def schema_id
      self.class.schema_id
    end

    def id
      schema_id.to_s
    end

    def schema_name
      _name.to_s
    end

    def owner_sid
      nil
    end

    def schema_owner
      nil
    end

    def formats
      _owner.formats
    end

    def media_id
      "#{_owner.padded_id}/#{schema_id}"
    end

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
            field_store << field.serialize_db
          end
        end
      end
      field_store
    end

    def field_modified!(modified_field)
      @modified = true
      _owner.box_modified!(self)
    end

    def serialize_db
      {
        :box_id => schema_id.to_s,
        :fields => fields.serialize_db
      }
    end

    def self.resolve_style(box)
      Spontaneous::BoxStyle.new(box)
    end

    def self.style_class
      Spontaneous::BoxStyle
    end

    def style
      resolve_style(self)
    end

    def container
      _owner
    end

    def page
      container.page
    end

    def depth
      container.content_depth
    end

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
      new_position = container.pieces.index(piece)
      container.pieces.set_position(entry, new_position)
    end

    def modified?
      @modified
    end

    def pieces
      @pieces ||= _owner.pieces.for_box(self)
    end


    def each
      pieces.each do |piece|
        yield piece if block_given?
      end
    end

    def content
      entries
    end

    def last
      pieces.last
    end

    def iterable
      pieces
    end

    def export(user = nil)
      shallow_export(user).merge({
        :entries => pieces.map { |p| p.export(user) }
      })
    end

    def shallow_export(user)
      {
        :name => _prototype.name.to_s,
        :id => _prototype.schema_id.to_s,
        :fields => self.class.readable_fields(user).map { |name| fields[name].export(user) }
      }
    end

    # only called directly after saving a boxes fields so
    # we don't need to return the entries
    def serialise_http(user)
      Spontaneous.serialise_http(shallow_export(user))
    end

    def writable?(user, content_type = nil)
      return true if Spontaneous::Permissions.has_level?(user, Spontaneous::Permissions.root)
      box_writable = self._owner.box_writable?(user, _name)
      if content_type
        allowed = self.allowed_type(content_type)
        box_writable && allowed && allowed.addable?(user)
      else
        box_writable
      end
    end

    def readable?(user)
      self._owner.box_readable?(user, _name)
    end

    def start_inline_edit_marker
      "spontaneous:previewedit:start:box id:#{schema_id}"
    end

    def end_inline_edit_marker
      "spontaneous:previewedit:end:box id:#{schema_id}"
    end

    def save
      _owner.save
    end
  end

end
