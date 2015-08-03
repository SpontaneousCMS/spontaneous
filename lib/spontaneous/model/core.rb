# encoding: UTF-8

module Spontaneous::Model
  module Core
    autoload :Aliases,          "spontaneous/model/core/aliases"
    autoload :Boxes,            "spontaneous/model/core/boxes"
    autoload :ContentGroups,    "spontaneous/model/core/content_groups"
    autoload :ContentHash,      "spontaneous/model/core/content_hash"
    autoload :EditorClass,      "spontaneous/model/core/editor_class"
    autoload :Entries,          "spontaneous/model/core/entries"
    autoload :Entry,            "spontaneous/model/core/entry"
    autoload :Fields,           "spontaneous/model/core/fields"
    autoload :InstanceCode,     "spontaneous/model/core/instance_code"
    autoload :Locks,            "spontaneous/model/core/locks"
    autoload :Media,            "spontaneous/model/core/media"
    autoload :Modifications,    "spontaneous/model/core/modifications"
    autoload :PageSearch,       "spontaneous/model/core/page_search"
    autoload :Permissions,      "spontaneous/model/core/permissions"
    autoload :Prototypes,       "spontaneous/model/core/prototypes"
    autoload :Publishing,       "spontaneous/model/core/publishing"
    autoload :Render,           "spontaneous/model/core/render"
    autoload :SchemaHierarchy,  "spontaneous/model/core/schema_hierarchy"
    autoload :SchemaId,         "spontaneous/model/core/schema_id"
    autoload :SchemaTitle,      "spontaneous/model/core/schema_title"
    autoload :Serialisation,    "spontaneous/model/core/serialisation"
    autoload :Styles,           "spontaneous/model/core/styles"
    autoload :Supertype,        "spontaneous/model/core/supertype"
    autoload :Visibility,       "spontaneous/model/core/visibility"
    autoload :CascadingChange,  "spontaneous/model/core/cascading_change"

    extend Spontaneous::Concern

    module ClassMethods
      include Spontaneous::Model::Page::Singleton::ContentClassMethods

      def page?
        false
      end

      def is_page?
        page?
      end

      # terminate the supertype chain here
      def supertype
        nil
      end

      def supertype?
        !supertype.nil?
      end

      def public_root
        content_model::Page.root
      end

      alias_method :root, :public_root

      def log_sql(io = $stdout)
        mapper.logger = ::Logger.new(io)
        yield if block_given?
      ensure
        mapper.logger = nil
      end

      # Provide a Content.to_proc implementation to
      # enable filtering of content lists like so:
      #
      #   Content.all.select(&ContentClass)
      #   => [#<ContentClass...>, #<ContentClass...>]
      #
      def to_proc
        Proc.new { |obj| self.===(obj) }
      end

      # Expands type testing to include peeking inside PagePiece instances
      def ===(other)
        return true if super
        return (self == other.content_class) if other.respond_to?(:content_class)
        false
      end
    end

    include Enumerable

    include CascadingChange
    include SchemaId
    include Entry
    include Boxes
    include Fields
    include Entries
    include Styles
    include SchemaTitle
    include Render
    include InstanceCode
    include Serialisation
    include Media
    include Publishing
    include Modifications
    include Aliases
    include Visibility
    include Prototypes
    include Permissions
    include ContentGroups
    include ContentHash
    include SchemaHierarchy
    include PageSearch
    include Locks

    # marker method enabling a simple test for "cms content" vs "everything else"
    def spontaneous_content?
      true
    end

    def alias?
      false
    end

    # Provide a default implementation of this that is later over-ridden by the page methods
    def is_public_root?
      false
    end

    def public_root
      is_public_root? ? self : content_model::Page.root
    end

    alias_method :root, :public_root

    def visibility_path_ids
      (self[:visibility_path] || "").split(ANCESTOR_SEP).map { |id| id.to_i }
    end

    def content_instance
      self
    end

    # Provides consistency between aliases & non-aliases
    # so that a mixed list of both can be treated the same
    # (for instance when ensuring uniqueness)
    def target
      self
    end

    # Returns a version of this object as a page.
    # This is used by the rendering system to guarantee that the object
    # it is recieving is a page & not a PagePiece proxy. See PagePiece#to_page
    def to_page
      page
    end

    def page?
      false
    end

    alias_method :is_page?, :page?

    def content_class
      self
    end

    # Do not overwrite this method directly.
    # If you want a page to render the content of another configure
    # the type using Content::render
    def renderable
      self
    end

    def start_inline_edit_marker
      "spontaneous:previewedit:start:content id:#{id}"
    end

    def end_inline_edit_marker
      "spontaneous:previewedit:end:content id:#{id}"
    end

    def to_s
      inspect
    end

    def inspect
      values = inspection_values.map { |(name, value)| "#{name}=#{value.inspect}" }.join(" ")
      %(#<#{self.class.name}:0x#{self.object_id.to_s(16)} #{values}>)
    end

    def inspection_values

      location = if container.nil?
                   [path]
                 elsif page
                   [page.path, container._name, position].compact
                 elsif container
                   [container._name, position]
                 else
                   []
                 end
      { :id => id, :location => location.join(":") }.merge(inspection_fields)
    end

    def inspection_fields
      crop = lambda{ |str|
        len = 23
        return str if str.length <= len
        str[0...len] + "…"
      }
      Hash[fields.map { |field| [field.name, crop[field.unprocessed_value.to_s]]}]
    end

    def each
      iterable.each do |i|
        yield i if block_given?
      end
    end

    def formats
      return page.formats if page
      [:html]
    end

    def log_sql(io = $stdout)
      mapper.logger = ::Logger.new(io)
      yield if block_given?
    ensure
      mapper.logger = nil
    end
  end
end
