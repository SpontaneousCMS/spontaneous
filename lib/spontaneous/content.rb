# encoding: UTF-8


require File.expand_path("../../sequel/plugins/yajl_serialization", __FILE__)
require File.expand_path("../../sequel/plugins/content_table_inheritance", __FILE__)

module Spontaneous
  class Content < Sequel::Model(:content)
    class << self
      alias_method :sequel_plugin, :plugin unless method_defined?(:sequel_plugin)
    end

    alias_method :each_attribute, :each

    # need to load this first because it's used by the ContentTableInheritance plugin
    plugin Plugins::SchemaId

    sequel_plugin :content_table_inheritance, :type_sid
    sequel_plugin :schema_uid, :type_sid, :style_sid, :box_sid
    sequel_plugin :yajl_serialization, :field_store, :entry_store, :box_store
    sequel_plugin :instance_hooks
    sequel_plugin :skip_create_refresh
    sequel_plugin :timestamps, :create=>:created_at, :update=>:modified_at
    sequel_plugin :identity_map
    sequel_plugin :association_dependencies

    # overwrite the sequel version defined in IdentityMap to support
    # revisions
    def self.identity_map_key(pk)
      "#{super}:#{revision}"
    end

    # must resolve my is_*? schizophrenia
    def self.page?
      false
    end

    def self.is_page?
      page?
    end

    many_to_one :container, :key => :container_id, :class => self, :reciprocal => :_pieces
    one_to_many :_pieces,    :key => :container_id, :class => self, :reciprocal => :container
    many_to_one :page, :class => Content, :key => :page_id, :reciprocal => :content

    extend Plugins

    # plugin Plugins::Slots
    plugin Plugins::Entry
    plugin Plugins::Boxes
    plugin Plugins::Fields
    plugin Plugins::Entries
    plugin Plugins::Styles
    plugin Plugins::SchemaTitle
    plugin Plugins::Render
    plugin Plugins::SchemaHierarchy
    plugin Plugins::InstanceCode
    plugin Plugins::JSON
    plugin Plugins::Media
    plugin Plugins::Publishing
    plugin Plugins::Aliases
    plugin Plugins::Visibility
    plugin Plugins::Prototypes
    plugin Plugins::Permissions


    include Enumerable

    def after_initialize
      if new?
        self.depth = 0
        self.path = ""
      end
      super
    end

    def alias?
      false
    end

    def page?
      false
    end
    alias_method :is_page?, :page?



    def meta
      class << self; self; end
    end

    def start_inline_edit_marker
      "spontaneous:previewedit:start:content id:#{id}"
    end

    def end_inline_edit_marker
      "spontaneous:previewedit:end:content id:#{id}"
    end

    def to_s
      %(#<#{self.class.name} id=#{id}>)
    end

    def each
      iterable.each do |i|
        yield i if block_given?
      end
    end
  end
end
