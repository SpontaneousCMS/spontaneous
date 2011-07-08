# encoding: UTF-8


if RUBY_VERSION < '1.9'
  $KCODE='u'
else
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

require "home_run"
require "stringex"
require "sequel"
require "yajl"

require 'logger'
require 'fileutils'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/core_ext/file'

Sequel.extension :inflector

Dir[File.join(File.dirname(__FILE__), 'spontaneous/extensions/*.rb')].each { |file|
  require file
}

require 'spontaneous/logger'
require 'spontaneous/plugins'
require 'spontaneous/constants'
require 'spontaneous/errors'

Dir[File.expand_path('../spontaneous/plugins/application/*.rb', __FILE__)].each do |file|
  require file
end

module Spontaneous
  extend Plugins
  include Constants

  def self.gem_root
    @gem_root ||= File.expand_path(File.dirname(__FILE__) / '..')
  end
  def self.reload!
    Spontaneous::Schema.reload!
    Spontaneous::Loader.reload!
    Spontaneous::Schema.validate!
  end

  plugin Plugins::Application::State
  plugin Plugins::Application::Paths
  plugin Plugins::Application::Render
  plugin Plugins::Application::Facets

  autoload :ProxyObject, "spontaneous/proxy_object"

  autoload :Config, "spontaneous/config"
  autoload :Paths, "spontaneous/paths"
  autoload :Facet, "spontaneous/facet"

  autoload :Content, "spontaneous/content"
  autoload :Page, "spontaneous/page"
  autoload :Piece, "spontaneous/piece"
  autoload :Box, "spontaneous/box"

  autoload :FieldTypes, "spontaneous/field_types"

  autoload :PagePiece, "spontaneous/page_piece"


  autoload :Style, "spontaneous/style"
  autoload :BoxStyle, "spontaneous/box_style"
  autoload :Layout, "spontaneous/layout"

  autoload :Site, "spontaneous/site"
  autoload :Schema, "spontaneous/schema"

  autoload :ImageSize, "spontaneous/image_size"

  autoload :Rack, "spontaneous/rack"

  autoload :Render, "spontaneous/render"
  autoload :Media, "spontaneous/media"

  autoload :Change, "spontaneous/change"
  autoload :Revision, "spontaneous/revision"
  autoload :Publishing, "spontaneous/publishing"

  autoload :Generators, "spontaneous/generators"

  autoload :Server, "spontaneous/server"

  autoload :Permissions, "spontaneous/permissions"
  autoload :ContentQuery, "spontaneous/content_query"

  autoload :PageController, "spontaneous/page_controller"

  autoload :Application, "spontaneous/application"

  module Prototypes
    autoload :FieldPrototype, "spontaneous/prototypes/field_prototype"
    autoload :BoxPrototype, "spontaneous/prototypes/box_prototype"
    autoload :StylePrototype, "spontaneous/prototypes/style_prototype"
    autoload :LayoutPrototype, "spontaneous/prototypes/layout_prototype"
  end

  module Collections
    autoload :PrototypeSet, "spontaneous/collections/prototype_set"
    autoload :ChangeSet, "spontaneous/collections/change_set"
    autoload :EntrySet, "spontaneous/collections/entry_set"
    autoload :FieldSet, "spontaneous/collections/field_set"
    autoload :BoxSet, "spontaneous/collections/box_set"
    autoload :StyleSet, "spontaneous/collections/style_set"
  end

  module Plugins
    autoload :Supertype, "spontaneous/plugins/supertype"
    autoload :Boxes, "spontaneous/plugins/boxes"
    autoload :Fields, "spontaneous/plugins/fields"
    autoload :Entries, "spontaneous/plugins/entries"
    autoload :Entry, "spontaneous/plugins/entry"
    autoload :Styles, "spontaneous/plugins/styles"
    autoload :Layouts, "spontaneous/plugins/layouts"
    autoload :SchemaTitle, "spontaneous/plugins/schema_title"
    autoload :SchemaId, "spontaneous/plugins/schema_id"
    autoload :Render, "spontaneous/plugins/render"
    autoload :SchemaHierarchy, "spontaneous/plugins/schema_hierarchy"
    autoload :InstanceCode, "spontaneous/plugins/instance_code"
    autoload :Paths, "spontaneous/plugins/paths"
    autoload :PageTree, "spontaneous/plugins/page_tree"
    autoload :AllowedTypes, "spontaneous/plugins/allowed_types"
    autoload :JSON, "spontaneous/plugins/json"
    autoload :SiteMap, "spontaneous/plugins/site_map"
    autoload :PageSearch, "spontaneous/plugins/page_search"
    autoload :Media, "spontaneous/plugins/media"
    autoload :Publishing, "spontaneous/plugins/publishing"
    autoload :Aliases, "spontaneous/plugins/aliases"
    autoload :Visibility, "spontaneous/plugins/visibility"
    autoload :Prototypes, "spontaneous/plugins/prototypes"
    autoload :Permissions, "spontaneous/plugins/permissions"
    autoload :Controllers, "spontaneous/plugins/controllers"


    module Site
      autoload :Publishing, "spontaneous/plugins/site/publishing"
    end
  end


  class UnknownTypeException < Exception
    def initialize(parent, type)
      super("Unknown content type '#{type}' requested in class #{parent}")
    end
  end
  class UnknownStyleException < Exception
    def initialize(style_name, klass)
      super("Unknown style '#{style_name}' for class #{klass}")
    end
  end

end

require 'spontaneous/loader'
require 'spontaneous/version'


Spot = S = Spontaneous unless defined?(Spot)
