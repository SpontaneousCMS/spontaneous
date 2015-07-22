# encoding: UTF-8


Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require "fileutils"
require "stringex"
require "logger"

require "active_support"
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

  autoload :Application,        "spontaneous/application"
  autoload :Asset,              "spontaneous/asset"
  autoload :Box,                "spontaneous/box"
  autoload :BoxStyle,           "spontaneous/box_style"
  autoload :Change,             "spontaneous/change"
  autoload :Cli,                "spontaneous/cli"
  autoload :Config,             "spontaneous/config"
  autoload :ContentQuery,       "spontaneous/content_query"
  autoload :Crypt,              "spontaneous/crypt"
  autoload :DataMapper,         "spontaneous/data_mapper"
  autoload :Facet,              "spontaneous/facet"
  autoload :Field,              "spontaneous/field"
  autoload :Generators,         "spontaneous/generators"
  autoload :Layout,             "spontaneous/layout"
  autoload :Media,              "spontaneous/media"
  autoload :Output,             "spontaneous/output"
  autoload :PagePiece,          "spontaneous/page_piece"
  autoload :PageLock,           "spontaneous/page_lock"
  autoload :Paths,              "spontaneous/paths"
  autoload :Permissions,        "spontaneous/permissions"
  autoload :PublishedRevision,  "spontaneous/published_revision"
  autoload :Publishing,         "spontaneous/publishing"
  autoload :PagePathHistory,    "spontaneous/page_path_history"
  autoload :Rack,               "spontaneous/rack"
  autoload :Revision,           "spontaneous/revision"
  autoload :Schema,             "spontaneous/schema"
  autoload :Search,             "spontaneous/search"
  autoload :Server,             "spontaneous/server"
  autoload :Simultaneous,       "spontaneous/simultaneous"
  autoload :Site,               "spontaneous/site"
  autoload :State,              "spontaneous/state"
  autoload :Style,              "spontaneous/style"
  autoload :Utils,              "spontaneous/utils"

  module Prototypes
    autoload :BoxPrototype,     "spontaneous/prototypes/box_prototype"
    autoload :FieldPrototype,   "spontaneous/prototypes/field_prototype"
    autoload :LayoutPrototype,  "spontaneous/prototypes/layout_prototype"
    autoload :StylePrototype,   "spontaneous/prototypes/style_prototype"
  end

  module Collections
    autoload :BoxContents,      "spontaneous/collections/box_contents"
    autoload :BoxSet,           "spontaneous/collections/box_set"
    autoload :ChangeSet,        "spontaneous/collections/change_set"
    autoload :FieldSet,         "spontaneous/collections/field_set"
    autoload :HashWithFallback, "spontaneous/collections/hash_with_fallback"
    autoload :PrototypeSet,     "spontaneous/collections/prototype_set"
    autoload :StyleSet,         "spontaneous/collections/style_set"
  end

  module Plugins
    module Application
      autoload :Facets,         "spontaneous/plugins/application/facets"
      autoload :Features,       "spontaneous/plugins/application/features"
      autoload :Paths,          "spontaneous/plugins/application/paths"
      autoload :Render,         "spontaneous/plugins/application/render"
      autoload :Serialisation,  "spontaneous/plugins/application/serialisation"
      autoload :State,          "spontaneous/plugins/application/state"
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
