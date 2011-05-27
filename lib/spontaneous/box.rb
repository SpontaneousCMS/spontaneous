# encoding: UTF-8

module Spontaneous
  class Box
    extend Plugins
    include Enumerable

    plugin Plugins::SchemaHierarchy
    plugin Plugins::Fields
    plugin Plugins::Styles
    plugin Plugins::JSON
    plugin Plugins::Render
    plugin Plugins::AllowedTypes
    plugin Plugins::Permissions

    # use underscores to protect against field name conflicts
    attr_reader :_name, :_prototype, :_owner


    def initialize(name, prototype, owner)
      @_name, @_prototype, @_owner = name.to_sym, prototype, owner
      @field_initialization = false
    end

    def self.schema_id
      Spontaneous::Schema.schema_id(self)
    end

    def self.schema_name
      "type//#{self.name}"
    end

    def schema_id
      # Spontaneous::Schema.schema_id(_owner.class, :box, _name.to_s)
      # _prototype.schema_id
      self.class.schema_id
    end

    def schema_name
      _name.to_s
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

    def self.resolve_style(box, format = :html)
      prototype = box._prototype
      owner_class = box._owner.class.style_directory_name
      box_class = prototype.box_base_class.style_directory_name

      # you can always over-ride the configured styles by having a template named after the box
      # in the style directory for its owning class
      possible_styles = [
        S::Style.new(self, owner_class, box._name),
      ]

      if styles.empty?
        possible_styles << S::Style.new(self, nil, box_class) if box_class
      else
        if style_name = prototype.default_style
          possible_styles << S::Style.new(self, owner_class, style_name)
          possible_styles << S::Style.new(self, box_class, style_name)
        else
          styles.each do |style|
            possible_styles << S::Style.new(self, owner_class, style.name, style.options)
            possible_styles << S::Style.new(self, box_class, style.name, style.options)
          end
        end
      end
      # anonymous styles always exist so this will be the result if all else fails
      possible_styles << anonymous_style
      possible_styles.detect { |s| s.exists? }
    end

    def self.anonymous_style
      Spontaneous::Style::Anonymous.new("{{ render_content }}")
    end


    def self.style_directory_name
      return nil if self == Spontaneous::Box
      super
    end

    def style(format = :html)
      resolve_style(self, format)
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

    def last
      pieces.last
    end

    def iterable
      pieces
    end

    def to_hash
      to_shallow_hash.merge({
        :entries => pieces.map { |p| p.to_hash }
      })
    end

    def to_shallow_hash
      {
        :id => _prototype.schema_id,
        :fields => self.class.readable_fields.map { |name| fields[name].to_hash }
      }
    end

    # only called directly after saving a boxes fields so
    # we don't need to return the entries
    def to_json
      to_shallow_hash.to_json
    end

    def writable?(content_type = nil)
      return true if Spontaneous::Permissions.has_level?(Spontaneous::Permissions.root)
      box_writable = self._owner.box_writable?(_name)
      if content_type
        allowed = self.allowed_type(content_type)
        box_writable && allowed && allowed.addable?
      else
        box_writable
      end
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

    def save
      _owner.save
    end
  end

end
