# encoding: UTF-8

module Spontaneous
  class Site < Spontaneous::Facet
    extend Plugins

    plugin Plugins::Site::Instance
    plugin Plugins::Site::Publishing
    plugin Plugins::Site::Revisions
    plugin Plugins::Site::Selectors
    plugin Plugins::Site::Map
    plugin Plugins::Site::Search
    plugin Plugins::Site::Features
    plugin Plugins::Site::Schema

    attr_accessor :database
    attr_reader :environment, :mode

    def initialize(root, env, mode)
      super(root)
      @environment, @mode = env, mode
    end

    def initialize!
      load_config!
      connect_to_database!
      find_plugins!
      load_facets!
      init_facets!
      init_indexes!
    end


    def init_facets!
      facets.each do |facet|
        facet.init!
      end
    end

    def init_indexes!
      facets.each do |facet|
        facet.load_indexes!
      end
    end

    def load_facets!
      Spontaneous::Loader.load!
    end

    def load_paths
      load_paths = []
      [:lib, :schema].each do |category|
        facets.each do |facet|
          load_paths += facet.paths.expanded(category)
        end
      end
      load_paths
    end

    def connect_to_database!
      self.database = Sequel.connect(db_settings)
      self.database.logger = logger if config.log_queries
    end

    def db_settings
      config_dir = paths.expanded(:config).first
      @db_settings = YAML.load_file(File.join(config_dir, "database.yml"))
      self.config.db = @db_settings[environment]
    end

    def config
      @config ||= Spontaneous::Config.new(environment, mode)
    end

    def find_plugins!
      paths.expanded(:plugins).each do |glob|
        Dir[glob].each do |path|
          load_plugin(path)
        end
      end
    end

    def plugins
      @plugins ||= []
    end

    def facets
      [self] + plugins
    end

    def load_plugin(plugin_root)
      plugin = Spontaneous::Application::Plugin.new(plugin_root)
      self.plugins <<  plugin
      plugin
    end

    def revision_root(*path)
      @revision_dir ||= File.expand_path(@root / 'cache/revisions')
      Spontaneous.relative_dir(@revision_dir, *path)
    end

    def revision_dir(revision=nil, root = revision_root)
      return root / 'current' if revision.nil?
      root / revision.to_s.rjust(5, "0")
    end
  end
end
