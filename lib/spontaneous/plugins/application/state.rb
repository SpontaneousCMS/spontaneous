# encoding: UTF-8


module Spontaneous::Plugins::Application
  module State

    def self.configure(base)
    end

    module ClassMethods
      def init(options={})
        # return false if loaded?
        self.environment = (options.delete(:environment) || ENV["SPOT_ENV"] || :development)
        self.mode = options.delete(:mode) || ENV["SPOT_MODE"] || :back
        Spot::Logger.setup(:log_level => options[:log_level], :logfile => options[:logfile], :cli => options[:cli])
        Spot::Config.load(self.environment, self.root)
        connect_to_database
        Spontaneous::Loader.load
        Spot::Schema.validate!
        Thread.current[:spontaneous_loaded] = true
      end

      def loaded?
        Thread.current[:spontaneous_loaded]
      end

      def connect_to_database
        self.database = Sequel.connect(db_settings)
      end

      attr_accessor :database

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

      def test?
        environment == :test
      end
    end # ClassMethods
  end # State
end

