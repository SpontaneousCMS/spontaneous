# encoding: UTF-8

module Spontaneous
  class Site < Spontaneous::Facet
    include Plugins::Site::Instance
    include Plugins::Site::Publishing
    include Plugins::Site::Revisions
    include Plugins::Site::Selectors
    include Plugins::Site::Map
    include Plugins::Site::Search
    include Plugins::Site::Features
    include Plugins::Site::Schema
    include Plugins::Site::Level
    include Plugins::Site::Storage

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
      load_order.each do |category|
        facets.each { |facet| facet.load_files(category) }
      end
    end


    def reload!
      schema.reload!
      facets.each { |facet| facet.reload_all! }
      schema.validate!
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

    # used by publishing mechanism to place files into the appropriate subdirectories
    # in the public folder.
    # Site#file_namespace returns nil so that it's files are placed at the root
    def file_namespace
      nil
    end

    def revision_root
      @revision_dir ||= File.expand_path(@root / 'cache/revisions')
      # Spontaneous.relative_dir(@revision_dir, *path)
    end

    def revision_dir(revision=nil, root = revision_root)
      root ||= revision_root
      return root / 'current' if revision.nil?
      root / revision.to_s.rjust(5, "0")
    end

    def media_dir(*path)
      media_root = root / "cache/media"
      return media_root if path.empty?
      File.join(media_root, *path)
    end

    def cache_dir(*path)
      cache_root = root / "cache"
      return cache_root if path.empty?
      File.join(cache_root, *path)
    end
  end
end
