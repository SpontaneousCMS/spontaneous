# encoding: UTF-8

require File.expand_path("../../sequel/plugins/content_table_inheritance", __FILE__)

module Spontaneous
  class Content < Sequel::Model(:content)
    class << self
      alias_method :sequel_plugin, :plugin unless method_defined?(:sequel_plugin)
    end

    alias_method :each_attribute, :each

    # need to load this first because it's used by the ContentTableInheritance plugin
    include Plugins::SchemaId

    sequel_plugin :content_table_inheritance, :type_sid
    sequel_plugin :serialization, :yajl, :field_store, :entry_store, :box_store
    sequel_plugin :instance_hooks
    sequel_plugin :skip_create_refresh
    sequel_plugin :timestamps, :create=>:created_at, :update=>:modified_at, :update_on_create => true
    sequel_plugin :identity_map
    sequel_plugin :association_dependencies
    sequel_plugin :defaults_setter
    sequel_plugin :scoped_table_name

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

    many_to_one :owner,   :key => :owner_id, :class => Content, :reciprocal => :_pieces
    one_to_many :_pieces, :key => :owner_id, :class => Content, :reciprocal => :owner
    many_to_one :page,    :key => :page_id,  :class => Content, :reciprocal => :content

    include Enumerable

    include Plugins::Entry
    include Plugins::Boxes
    include Plugins::Fields
    include Plugins::Entries
    include Plugins::Styles
    include Plugins::SchemaTitle
    include Plugins::Render
    include Plugins::SchemaHierarchy
    include Plugins::InstanceCode
    include Plugins::Serialisation
    include Plugins::Media
    include Plugins::Publishing
    include Plugins::Aliases
    include Plugins::Visibility
    include Plugins::Prototypes
    include Plugins::Permissions

    # marker method enabling a simple test for "cms content" vs "everything else"
    def spontaneous_content?
      true
    end

    def alias?
      false
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



    # terminate the supertype chain here
    def self.supertype
      nil
    end

    def self.supertype?
      !supertype.nil?
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

    def formats
      return page.formats if page
      [:html]
    end
  end
end
