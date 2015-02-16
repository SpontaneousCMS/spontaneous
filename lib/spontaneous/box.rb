# encoding: UTF-8

module Spontaneous
  class Box
    include Enumerable

    include Spontaneous::Model::Core::SchemaHierarchy
    include Spontaneous::Model::Core::Fields
    include Spontaneous::Model::Core::Styles
    include Spontaneous::Model::Core::Serialisation
    include Spontaneous::Model::Core::Render
    include Spontaneous::Model::Box::AllowedTypes
    include Spontaneous::Model::Core::Permissions
    include Spontaneous::Model::Core::Media
    include Spontaneous::Model::Core::ContentHash::BoxMethods

    # use underscores to protect against field name conflicts
    attr_reader :_name, :_prototype, :owner
    attr_accessor :template_params

    # Public: the parent of a Box is the same as its owner,
    # i.e. the Content object that contains it.
    #
    # Returns: the owning Content object
    alias_method :parent, :owner

    class << self
      attr_reader :mapper
    end

    def self.page?
      false
    end

    def self.is_box?
      true
    end

    # Used in the instance that a subclass is re-opening a box definition
    # In that case the box prototype is created by a BoxPrototype#merge
    # call and at that point we force the box instance class to use the same
    # schema id as its parent so that content is always connected to the originating
    # definition in the supertype rather than the customised version in the subclass
    def self.schema_id=(schema_id)
      @schema_id = schema_id
    end

    def self.schema_id
      mapper.schema.uids[@schema_id] || mapper.schema.to_id(self)
    end

    # This is overridden by anonymous classes defined by box prototypes
    # See BoxPrototype#create_instance_class
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
      !supertype.nil?
    end

    def self.owner_sid
      nil
    end

    def initialize(name, prototype, owner)
      @_name, @_prototype, @owner = name.to_sym, prototype, owner
      @field_initialization = false
    end

    def model
      @owner.model
    end

    # All renderable objects must implement #target to enable aliases & content objects
    # to be treated identically
    def target
      self
    end

    def renderable
      self
    end

    def render(format = :html, params = {}, parent_context = nil)
      render_inline(format, params, parent_context)
    end

    def render_using(renderer, format = :html, params = {}, parent_context = nil)
      render_inline_using(renderer, format, params, parent_context)
    end

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

    # A boxes "identity" must be a combination of its owner's id and
    # its schema_id.
    def id
      [owner.id, schema_id.to_s].join("/")
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
      owner.formats
    end

    def media_id
      "#{owner.padded_id}/#{schema_id}"
    end

    def position
      _prototype.position
    end

    def box_name
      _name
    end

    def label
      _name.to_s
    end

    def reload
      owner.reload
    end
    # needed by Render::Context
    def box?(box_name)
      false
    end


    def field_store
      owner.box_field_store(self) || initialize_fields
    end

    # don't like this
    def initialize_fields
      field_store = nil
      if default_values = _prototype.field_defaults
        field_store = []
        default_values.each do |field_name, value|
          if self.field?(field_name)
            field = self.class.field_prototypes[field_name].to_field(self)
            field.value = value
            field_store << field.serialize_db
          end
        end
      end
      field_store
    end

    def field_modified!(modified_field = nil)
      save_fields!
    end

    def save_fields(fields = nil)
      save_fields!(fields)
      save
    end

    # Use @serialized_fields to temporarily overwrite the value of
    # #serialized_fields because this call may be coming from an async
    # process that only wants to update a subset of the field values
    # and because we don't have direct access to the serialization
    # store we have to control our serialization output.
    # TODO: Make boxes responsible for directly writing their serialized
    # form
    def save_fields!(fields = nil)
      @modified = true
      @serialized_fields = update_serialized_fields(fields)
      owner.box_modified!(self)
      @serialized_fields = nil
    end

    def serialize_db
      { :box_id => schema_id.to_s,
        :fields => serialized_fields }
    end

    def serialized_fields
      @serialized_fields || fields.serialize_db
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

    # Container represents the object one level up from us,
    # which in this case is the parent Content instance.
    def container
      owner
    end

    def content_instance
      owner
    end

    # A pointer to the containing page. This may not be the same as the
    # `owner` of the box in the case where the box is owned by a Piece.
    def page
      owner.page
    end

    # A convenience method to return the root of the page tree
    def root
      page.root
    end

    # Used to determine the page to use to define the path of any
    # contained pages.
    #
    # Overwrite this to set up custom paths for pages.
    #
    # It can either return a page instance (in which case
    # child pages will be based on the #path of the returned
    # instance) or a string (which will form the root of the
    # generated paths:
    #
    #     Page.box :sections
    #
    #     Page.box :custom do
    #       def path_origin
    #         root
    #       end
    #     end
    #
    #     home = Page.create # set up a new site homepage
    #     section = Page.create(slug: 'a-section')
    #     home.sections << section # add section page to the root
    #     section.custom.path_origin.path #=> "/"
    #
    #     child = Page.create(slug: 'child')
    #     section.custom << child
    #     child.path #=> "/child" # this would normally be "/a-section/child"
    #
    def path_origin
      page
    end

    # This is used by new pages to generate the path component of the container.
    def path!
      case (origin = path_origin)
      when @owner.content_model
        origin.path!
      else
        origin.to_s
      end
    end

    alias_method :to_page, :page

    def depth
      owner.content_depth
    end

    def adopt(content, index = -1)
      content.parent.destroy_entry!(content)
      insert(index, content)
      self.save
      content.save
      # kinda feel like this should be dealt with internally by the page
      # but don't care enough to start messing with the path propagation
      # methods...
      content.propagate_path_changes if content.is_page?
    end

    def push(content)
      insert(-1, content)
    end

    alias_method :<<, :push

    def insert(index, content)
      @modified = true
      @contents = nil
      owner.insert(index, content, self)
    end

    def set_position(entry, new_position)
      @modified = true
      # piece = contents[new_position]
      # new_position = owner.pieces.index(piece)
      owner.contents.set_position(entry, new_position)
    end

    def modified?
      @modified
    end

    def contents
      owner.contents.for_box(self)
    end

    def pieces
      contents.select { |e| e.is_a?(Spontaneous::Model::Piece) }
    end

    def [](index)
      contents[index]
    end

    def index(entry)
      contents.index(entry)
    end

    def each
      contents.each do |piece|
        yield piece if block_given?
      end
    end

    def empty?
      contents.count == 0
    end

    def last
      contents.last
    end

    def length
      contents.length
    end

    alias_method :size, :length

    def iterable
      contents
    end

    def export(user = nil)
      shallow_export(user).merge({
        :entries => contents.map { |p| p.export(user) }
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
      box_writable = self.owner.box_writable?(user, _name)
      if content_type
        allowed = self.allowed_type(content_type)
        box_writable && allowed && allowed.addable?(user)
      else
        box_writable
      end
    end

    def readable?(user)
      self.owner.box_readable?(user, _name)
    end

    def start_inline_edit_marker
      "spontaneous:previewedit:start:box id:#{schema_id}"
    end

    def end_inline_edit_marker
      "spontaneous:previewedit:end:box id:#{schema_id}"
    end

    def save
      owner.save
    end

    def ==(obj)
      super or (obj.is_a?(Box) && (self._prototype == obj._prototype) && (self.owner == obj.owner))
    end
  end
end
