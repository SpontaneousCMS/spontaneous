# encoding: UTF-8

module Spontaneous
  module Application
    class Instance < Spontaneous::Facet
      attr_accessor :database
      attr_reader :environment, :mode

      def initialize(root, env, mode)
        super(root)
        @environment, @mode = env, mode
      end

      def initialize!
        connect_to_database!
        find_plugins!
        load_facets!
      end

      def load_facets!
        facets.each do |facet|
          facet.load!
        end
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
    end # Instance
  end # Application
end # Spontaneous
