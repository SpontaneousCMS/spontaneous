# encoding: UTF-8

module Spontaneous::Plugins::Application
  module State
    extend Spontaneous::Concern

    module ClassMethods
      def init(options={})
        # return false if loaded?
        self.environment = (options.delete(:environment) || ENV["SPOT_ENV"] || :development)
        self.mode = options.delete(:mode) || ENV["SPOT_MODE"] || :back
        root = options.delete(:root) || ENV["SPOT_ROOT"] || Dir.pwd
        site = Spontaneous::Site.instantiate(root, environment, mode)
        lib = File.expand_path(File.join(root, "lib"))
        $:.push(lib) unless $:.include?(lib)
        Spontaneous::Logger.setup(:log_level => options[:log_level], :logfile => options[:logfile], :cli => options[:cli])
        site.initialize!
        site.schema.validate! if self.mode == :console
        logger.warn "Auto login is enabled and set to '#{site.config.auto_login}'. Please ensure this is disabled in production mode by removing the 'auto_login' setting from your environment file." if site.config.auto_login and mode == :back
        Thread.current[:spontaneous_loaded] = true
      end

      # This is called after definition of the Content model.
      #
      #   Site = Spontaneous.site(Content)
      #
      # It is a safe way to define the content model that should be used
      # globally as it checks for its existance before overwriting.
      #
      # I could do the assignment of Spontaneous::Content automatically
      # after creation of the first content model, but this method provides
      # a nice way to create the ::Site constant in the user/site code
      def site(content_model)
        site!(content_model) unless defined?(Spontaneous::Content)
        Spontaneous::Site
      end

      # This forces the assignment of Spontaneous::Content, overwriting any
      # previous value.
      #
      # Used in tests.
      #
      def site!(content_model)
        spot = ::Spontaneous
        Spontaneous.send :remove_const, :Content if defined?(Spontaneous::Content)
        Spontaneous.const_set(:Content, content_model)
        Spontaneous::Site
      end

      def loaded?
        Thread.current[:spontaneous_loaded]
      end


      def config
        Spontaneous::Site.instance.config
      end

      def db_settings
        YAML.load_file(root /  "config/database.yml")[environment]
      end

      def database
        Spontaneous::Site.instance.database
      end

      def database=(database)
        Spontaneous::Site.instance.database = database
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
