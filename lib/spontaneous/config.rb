
module Spontaneous
  module Config

    class Loader
      def self.read(settings, file)
        self.new(settings, file).load
      end

      def initialize(settings, file)
        @settings, @file = settings, file
      end

      def load
        instance_eval(File.read(@file))
      end

      def method_missing(parameter, *args, &block)
        if args.length == 1
          args = args[0]
        end
        @settings[parameter] = args
      end
    end

    class Configuration
      extend Forwardable

      def initialize(name, settings)
        @name, @settings = name, settings

        @settings.each do |key, value|
          add_setting(key, value)
        end
      end

      def add_setting(key, value)
        meta = \
          class << self; self; end
        meta.send(:define_method, key) do
          value
        end
      end

      def get_setting(key)
        v = @settings[key]
        if v.is_a?(Proc)
          v.call
        else
          v
        end
      end

      def [](key)
        get_setting(key)
      end

      def method_missing(key, *args, &block)
        if key.to_s =~ /=$/
          key = key.to_s.gsub(/=$/, '').to_sym
          @settings[key] = args[0]
        else
          if @settings.key?(key)
            get_setting(key)
          else
            Config.base[key]
          end
        end
      end

      def_delegators :@settings, :key?, :[]=
    end

    @@local = Configuration.new(:local, {})
    @@environments = Hash.new { |hash, key| hash[key] = {} }
    @@base = Configuration.new(:base, {})
    @@defaults = Configuration.new(:defaults, {
      #TODO: add in sensible default configuration
    })

    class << self
      def load(pwd=Dir.pwd)
        Loader.read(@@base, File.join(pwd, 'config/environment.rb'))
        Dir.glob('config/environments/*.rb').each do |file|
          environment = File.basename(file, '.rb').to_sym
          store = {}
          Loader.read(store, File.join(pwd, file))
          @@environments[environment] = Configuration.new(environment, store)
        end
      end

      def defaults
        @@defaults
      end

      def environment
        @environment ||= :development
      end

      def environment=(env)
        @environment = env.to_sym
      end

      def configuration
        @@environments[environment]
      end

      def base
        @@base
      end

      def [](env)
        @@environments[env]
      end

      def method_missing(key, *args, &block)
        if key.to_s =~ /=$/
          key = key.to_s.gsub(/=$/, '').to_sym
          @@local[key] = args[0]
        else
          if @@local.key?(key)
            @@local[key]
          elsif configuration.key?(key)
            configuration[key]
          elsif base.key?(key)
            base[key]
          elsif defaults.key?(key)
            defaults[key]
          else
            # acting like a hash and returning nil for an unknown setting
            nil
          end
        end
      end
    end
  end
end

# automatically load the config if it looks like we're in an app dir
if File.exist?('config/environment.rb')
  Spontaneous::Config.load
end

