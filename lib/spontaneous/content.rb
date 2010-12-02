# encoding: UTF-8


require File.expand_path("../../sequel/plugins/yajl_serialization", __FILE__)
require File.expand_path("../../sequel/plugins/content_table_inheritance", __FILE__)

module Spontaneous
  class Content < Sequel::Model(:content)
    class << self
      alias_method :sequel_plugin, :plugin
    end

    alias_method :each_attribute, :each

    sequel_plugin :content_table_inheritance, :type_id
    sequel_plugin :yajl_serialization, :field_store, :entry_store
    sequel_plugin :instance_hooks
    sequel_plugin :skip_create_refresh
    sequel_plugin :timestamps, :create=>:created_at, :update=>:modified_at
    sequel_plugin :identity_map

    # overwrite the sequel version defined in IdentityMap to support
    # revisions
    def self.identity_map_key(pk)
      "#{super}:#{revision}"
    end

    extend Plugins

    plugin Plugins::Slots
    plugin Plugins::Fields
    plugin Plugins::Entries
    plugin Plugins::Styles
    plugin Plugins::SchemaTitle
    plugin Plugins::Render
    plugin Plugins::SchemaHierarchy
    plugin Plugins::InstanceCode
    plugin Plugins::AllowedTypes
    plugin Plugins::JSON
    plugin Plugins::Media
    plugin Plugins::Publishing

    many_to_one :container, :class => self, :reciprocal => :nodes
    one_to_many :nodes,    :key => :container_id, :class => self, :reciprocal => :container
    many_to_one :page, :class => Content, :key => :page_id, :reciprocal => :facets


    def after_initialize
      if new?
        self.depth = 0
        self.path = ""
      end
      super
    end


    def page?
      false
    end



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
  end
end
