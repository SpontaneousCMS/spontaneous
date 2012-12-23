# encoding: UTF-8


Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "fileutils"
require "stringex"
require "logger"

require "active_support/concern"
require "active_support/deprecation"
require "active_support/time"
require 'active_support/core_ext/class/attribute'
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/array/grouping"
require "active_support/core_ext/array/extract_options"
require "active_support/core_ext/file"



module Spontaneous

  require "spontaneous/logger"
  require "spontaneous/concern"
  require "spontaneous/constants"
  require "spontaneous/errors"
  require "spontaneous/json"
  require "spontaneous/sequel"
  require "spontaneous/model"

  include Constants

  def self.gem_root
    @gem_root ||= File.expand_path(File.dirname(__FILE__) / "..")
  end

  def self.reload!
    instance.reload!
  end

  autoload :Config,           "spontaneous/config"
  autoload :DataMapper,       "spontaneous/data_mapper"
  autoload :Paths,            "spontaneous/paths"
  autoload :Facet,            "spontaneous/facet"
  autoload :Box,              "spontaneous/box"
  autoload :FieldTypes,       "spontaneous/field_types"
  autoload :FieldVersion,     "spontaneous/field_version"
  autoload :PagePiece,        "spontaneous/page_piece"
  autoload :Style,            "spontaneous/style"
  autoload :BoxStyle,         "spontaneous/box_style"
  autoload :Layout,           "spontaneous/layout"
  autoload :Site,             "spontaneous/site"
  autoload :State,            "spontaneous/state"
  autoload :Schema,           "spontaneous/schema"
  autoload :ImageSize,        "spontaneous/image_size"
  autoload :Rack,             "spontaneous/rack"
  autoload :Output,           "spontaneous/output"
  autoload :Media,            "spontaneous/media"
  autoload :Change,           "spontaneous/change"
  autoload :Revision,         "spontaneous/revision"
  autoload :Publishing,       "spontaneous/publishing"
  autoload :Generators,       "spontaneous/generators"
  autoload :Server,           "spontaneous/server"
  autoload :Permissions,      "spontaneous/permissions"
  autoload :ContentQuery,     "spontaneous/content_query"
  autoload :Application,      "spontaneous/application"
  autoload :Search,           "spontaneous/search"
  autoload :Storage,          "spontaneous/storage"
  autoload :Cli,              "spontaneous/cli"
  autoload :Utils,            "spontaneous/utils"
  autoload :Asset,            "spontaneous/asset"

  module Prototypes
    autoload :FieldPrototype,   "spontaneous/prototypes/field_prototype"
    autoload :BoxPrototype,     "spontaneous/prototypes/box_prototype"
    autoload :StylePrototype,   "spontaneous/prototypes/style_prototype"
    autoload :LayoutPrototype,  "spontaneous/prototypes/layout_prototype"
  end

  module Collections
    autoload :PrototypeSet,     "spontaneous/collections/prototype_set"
    autoload :ChangeSet,        "spontaneous/collections/change_set"
    autoload :EntrySet,         "spontaneous/collections/entry_set"
    autoload :FieldSet,         "spontaneous/collections/field_set"
    autoload :BoxSet,           "spontaneous/collections/box_set"
    autoload :StyleSet,         "spontaneous/collections/style_set"
  end

  module Plugins
    module Application
      autoload :State,          "spontaneous/plugins/application/state"
      autoload :Paths,          "spontaneous/plugins/application/paths"
      autoload :Render,         "spontaneous/plugins/application/render"
      autoload :Facets,         "spontaneous/plugins/application/facets"
      autoload :Serialisation,  "spontaneous/plugins/application/serialisation"
      autoload :Features,       "spontaneous/plugins/application/features"
      autoload :System,         "spontaneous/plugins/application/system"
    end
  end

  include Plugins::Application::State
  include Plugins::Application::Paths
  include Plugins::Application::Render
  include Plugins::Application::Facets
  include Plugins::Application::Serialisation
  include Plugins::Application::Features
  include Plugins::Application::System
end

Dir["#{File.expand_path("../spontaneous", __FILE__)}/extensions/*.rb"].each { |file| require file }

require "spontaneous/loader"
require "spontaneous/version"


Spot = S = Spontaneous unless defined?(Spot)
