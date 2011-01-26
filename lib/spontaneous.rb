# encoding: UTF-8


require "home_run"
require "stringex"
require "sequel"
require "yajl"

require 'logger'
require 'fileutils'

Sequel.extension :inflector

require 'spontaneous/logger'

module Spontaneous
  autoload :Constants, "spontaneous/constants"
  include Constants
  class << self
    def init(options={})
      # return false if loaded?
      self.environment = (options.delete(:environment) || ENV["SPOT_ENV"] || :development)
      self.mode = options.delete(:mode) || ENV["SPOT_MODE"] || :back
      Logger.setup(:log_level => options[:log_level], :logfile => options[:logfile], :cli => options[:cli])
      Config.load
      connect_to_database
      Schema.load
      Thread.current[:spontaneous_loaded] = true
    end

    def loaded?
      Thread.current[:spontaneous_loaded]
    end

    def connect_to_database
      self.database = Sequel.connect(db_settings)
    end

    def database=(database)
      @database = database
    end

    def database
      @database
    end

    def config
      Spontaneous::Config
    end

    def mode_settings
      config_file = root / "config" / "#{mode}.yml"
      config = YAML.load_file(config_file)
      config[environment]
    end

    def db_settings
      @db_settings = YAML.load_file(File.join(config_dir, "database.yml"))
      self.config.db = @db_settings[environment]
    end

    def mode=(mode)
      @mode = mode.to_sym
    end

    def mode
      @mode
    end

    def front?
      mode == :front
    end

    def back?
      mode == :back
    end

    def environment=(env)
      @environment = env.to_sym rescue environment
    end
    alias_method :env=, :environment=

    def environment
      @environment ||= (ENV["SPOT_ENV"] || :development).to_sym
    end

    alias_method :env, :environment

    def development?
      environment == :development
    end

    def production?
      environment == :production
    end

    def log_dir(*path)
      relative_dir(root / "log", *path)
    end

    def config_dir(*path)
      relative_dir(root / "config", *path)
    end

    def template_root=(template_root)
      Render.template_root = template_root.nil? ? nil : File.expand_path(template_root)
    end

    def template_root(*path)
      relative_dir(Render.template_root, *path)
    end

    def template_path(*args)
      File.join(template_root, *args)
    end

    def schema_root=(schema_root)
      @schema_root = schema_root
    end

    def schema_root(*path)
      @schema_root ||= root / "schema"
      relative_dir(@schema_root, *path)
    end

    def template_ext
      Cutaneous.extension
    end

    attr_accessor :render_engine

    def media_dir=(dir)
      @media_dir = File.expand_path(dir)
    end

    def media_dir(*path)
      @media_dir ||= File.expand_path(root / "../media")
      relative_dir(@media_dir, *path)
    end

    def media_path(*args)
      Media.media_path(*args)
    end

    def root(*path)
      @root ||= File.expand_path(ENV[Spontaneous::ENV_ROOT] || Dir.pwd)
      relative_dir(@root, *path)
    end

    def root=(root)
      @root = File.expand_path(root)
    end

    def revision_root(*path)
      @revision_dir ||= File.expand_path(root / '../revisions')
      relative_dir(@revision_dir, *path)
    end

    def revision_root=(revision_dir)
      @revision_dir = File.expand_path(revision_dir)
    end

    def gem_dir(*path)
      @gem_dir ||= File.expand_path(File.dirname(__FILE__) / '..')
      relative_dir(@gem_dir, *path)
    end

    def application_dir(*path)
      @application_dir ||= File.expand_path("../../application", __FILE__)
      relative_dir(@application_dir, *path)
    end

    # def application_file(*args)
    #   File.join(application_dir, *args)
    # end

    def static_dir(*path)
      application_dir / "static"
      relative_dir(application_dir / "static", *path)
    end

    def js_dir(*path)
      relative_dir(application_dir / "js", *path)
    end

    def css_dir(*path)
      relative_dir(application_dir / "css", *path)
    end

    private

    def relative_dir(root, *path)
      File.join(root, *path)
    end
  end

  autoload :ProxyObject, "spontaneous/proxy_object"
  autoload :Plugins, "spontaneous/plugins"
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

S = Spot = Spontaneous
