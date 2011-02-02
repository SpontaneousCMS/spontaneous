# encoding: UTF-8


require "home_run"
require "stringex"
require "sequel"
require "yajl"

require 'logger'
require 'fileutils'

Sequel.extension :inflector

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
  include Errors

  def self.gem_root
    @gem_root ||= File.expand_path(File.dirname(__FILE__) / '..')
  end

  plugin Plugins::Application::State
  plugin Plugins::Application::Paths
  plugin Plugins::Application::Render

  autoload :ProxyObject, "spontaneous/proxy_object"
  autoload :Logger, "spontaneous/logger"

  autoload :Config, "spontaneous/config"


  autoload :Content, "spontaneous/content"
  autoload :Page, "spontaneous/page"
  autoload :Facet, "spontaneous/facet"

  autoload :FieldTypes, "spontaneous/field_types"

  autoload :Entry, "spontaneous/entry"
  autoload :PageEntry, "spontaneous/page_entry"
  autoload :EntrySet, "spontaneous/entry_set"


  autoload :Style, "spontaneous/style"
  autoload :StyleDefinitions, "spontaneous/style_definitions"
  autoload :RenderContext, "spontaneous/render_context"
  autoload :RenderFormatProxy, "spontaneous/render_format_proxy"

  autoload :Site, "spontaneous/site"
  autoload :Schema, "spontaneous/schema"

  autoload :ImageSize, "spontaneous/image_size"

  autoload :Rack, "spontaneous/rack"

  autoload :Render, "spontaneous/render"
  autoload :Templates, "spontaneous/templates"
  autoload :Media, "spontaneous/media"

  autoload :Change, "spontaneous/change"
  autoload :ChangeSet, "spontaneous/change_set"
  autoload :Revision, "spontaneous/revision"
  autoload :Publishing, "spontaneous/publishing"

  autoload :Generators, "spontaneous/generators"

  autoload :Server, "spontaneous/server"

  module Templates
    autoload :TemplateBase, "spontaneous/templates/template_base"
    autoload :ErubisTemplate, "spontaneous/templates/erubis_template"
  end

  module Plugins
    autoload :Slots, "spontaneous/plugins/slots"
    autoload :Fields, "spontaneous/plugins/fields"
    autoload :Entries, "spontaneous/plugins/entries"
    autoload :Styles, "spontaneous/plugins/styles"
    autoload :SchemaTitle, "spontaneous/plugins/schema_title"
    autoload :Render, "spontaneous/plugins/render"
    autoload :SchemaHierarchy, "spontaneous/plugins/schema_hierarchy"
    autoload :InstanceCode, "spontaneous/plugins/instance_code"
    autoload :PageStyles, "spontaneous/plugins/page_styles"
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

    module Slots
      autoload :SlotDefinitions, "spontaneous/plugins/slots/slot_definitions"
      autoload :SlotSet, "spontaneous/plugins/slots/slot_set"
      autoload :Slot, "spontaneous/plugins/slots/slot"
    end

    module Fields
      autoload :FieldPrototype, "spontaneous/plugins/fields/field_prototype"
      autoload :FieldSet, "spontaneous/plugins/fields/field_set"
    end

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

require 'spontaneous/version'

Dir[File.join(File.dirname(__FILE__), 'spontaneous', 'extensions', '*.rb')].each do |extension|
  require extension
end

Spot = S = Spontaneous unless defined?(Spot)

