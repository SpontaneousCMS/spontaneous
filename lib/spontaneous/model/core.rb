# encoding: UTF-8

module Spontaneous::Model
  module Core
    autoload :Aliases,          "spontaneous/model/core/aliases"
    autoload :Boxes,            "spontaneous/model/core/boxes"
    autoload :ContentGroups,    "spontaneous/model/core/content_groups"
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

    extend Spontaneous::Concern

    module ClassMethods
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

      def root
        content_model::Page.root
      end

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
        Proc.new { |obj| self === obj }
      end
    end

    include Enumerable

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

    def root
      content_model::Page.root
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

    def page?
      false
    end

    alias_method :is_page?, :page?

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
      %(#<#{self.class.name} #{values}>)
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
      Hash[fields.map { |field| [field.name, crop[field.unprocessed_value]]}]
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
