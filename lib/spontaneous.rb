
Sequel.extension :inflector

require 'logger'
module Spontaneous
  SLASH = "/".freeze
  class << self
    def init(options={})
      self.environment = options.delete(:environment) || :development
      self.mode = options.delete(:mode) || :back
      self.config = options
      # DataMapper::Logger.new(log_dir / "#{mode}.log", :debug)
      # DataMapper.setup(:default, db_settings)
      self.database = Sequel.connect(db_settings.merge(:logger => [Logger.new($stdout)] ))
      Schema.load
    end

    def database=(database)
      @database = database
    end

    def database
      @database
    end

    def config=(config={})
      config.delete(:db)
      @config = {
        :template_root => root / "templates",
        :template_extension => "erb",
        :db => db_settings
      }
      @config[mode] = mode_settings
      @config.merge(config)
    end

    def config
      @config
    end

    def log_dir
      root / "log"
    end

    def config_dir
      root / "config"
    end

    def mode_settings
      config_file = root / "config" / "#{mode}.yml"
      config = YAML.load_file(config_file)
      config[environment]
    end

    def db_settings
      @db_settings = YAML.load_file(File.join(config_dir, "database.yml"))
      @db_settings[environment]
    end

    def mode=(mode)
      @mode = mode
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
      @environment = env
    end

    def environment
      @environment
    end

    alias_method :env, :environment

    def development?
      environment == :development
    end

    def production?
      environment == :production
    end

    def template_root=(template_root)
      @template_root = template_root
    end

    def template_root
      @template_root ||= root / "templates"
    end

    def schema_root=(schema_root)
      @schema_root = schema_root
    end

    def schema_root
      @schema_root ||= root / "schema"
    end

    def template_ext
      "erb"
    end

    def media_dir=(dir)
      @media_dir = File.expand_path(dir)
    end

    def media_dir
      @media_dir ||= File.expand_path(root / "../media")
    end

    def root
      @root ||= File.expand_path(Dir.pwd)
    end

    def root=(root)
      @root = File.expand_path(root)
    end

  end

  autoload :ProxyObject, "spontaneous/proxy_object"
  autoload :Plugins, "spontaneous/plugins"

  autoload :Content, "spontaneous/content"
  autoload :Page, "spontaneous/page"
  autoload :Facet, "spontaneous/facet"

  autoload :FieldTypes, "spontaneous/field_types"

  autoload :Entry, "spontaneous/entry"
  autoload :PageEntry, "spontaneous/page_entry"
  autoload :EntrySet, "spontaneous/entry_set"


  autoload :Style, "spontaneous/style"
  autoload :StyleDefinitions, "spontaneous/style_definitions"
  autoload :Template, "spontaneous/template"
  autoload :RenderContext, "spontaneous/render_context"
  autoload :RenderFormatProxy, "spontaneous/render_format_proxy"

  autoload :Schema, "spontaneous/schema"

  autoload :ImageSize, "spontaneous/image_size"

  autoload :Rack, "spontaneous/rack"

  module TemplateTypes
    autoload :ErubisTemplate, "spontaneous/template_types/erubis_template"
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

    module Slots
      autoload :SlotDefinitions, "spontaneous/plugins/slots/slot_definitions"
      autoload :SlotSet, "spontaneous/plugins/slots/slot_set"
      autoload :Slot, "spontaneous/plugins/slots/slot"
    end

    module Fields
      autoload :FieldPrototype, "spontaneous/plugins/fields/field_prototype"
      autoload :FieldSet, "spontaneous/plugins/fields/field_set"
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

Dir[File.join(File.dirname(__FILE__), 'spontaneous', 'extensions', '*.rb')].each do |extension|
  require extension
end

