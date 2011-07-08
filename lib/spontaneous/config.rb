require 'forwardable'

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
        @settings
      end


      def back(&block)
        __mode__(:back, &block)
      end

      def front(&block)
        __mode__(:front, &block)
      end

      def __mode__(mode, &block)
        if Spontaneous.mode == mode
          yield if block_given?
        end
      end

      def method_missing(parameter, *args)
        if args.length == 1
          args = args[0]
        end
        @settings[parameter] = args
      end
    end

    class Configuration
      extend ::Forwardable

      def initialize(settings={})
        @settings = {}
        merge!(settings)
      end

      def merge!(hash)
        hash.each do |key, value|
          add_setting(key, value)
        end
      end
      def add_setting(key, value)
        @settings[key] = value
        singleton_class.send(:define_method, key) do
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

      def method_missing(key, *args)
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

    @@local = nil
    @@environment = Configuration.new
    @@base = Configuration.new
    @@defaults = Configuration.new({
      #TODO: add in sensible default configuration (or do it in the generators)
    })
    @@loaded = false

    class << self
      def init(environment=:development)
        @environment = environment.to_sym
        @@base = Configuration.new
        @@local = nil
        @@environment = Configuration.new
      end

      def load(config_root)
        default = File.join(config_root, 'environment.rb')
        Loader.read(@@base, default) if File.exist?(default)
        store = Hash.new
        file =  File.join(config_root, "environments/#{environment}.rb")
        Loader.read(store, file) if ::File.exists?(file)
        @@environment.merge!(store)
      end

      def load!
        # load unless @@loaded
      end

      def defaults
        @@defaults
      end

      def environment
        @environment || Spontaneous.env
      end

      # def environment=(env)
      #   self.load(env.to_sym)
      # end

      def configuration
        # load!
        @@environment
      end

      def base
        # load!
        @@base
      end

      def [](key)
        if local.key?(key)
          local[key]
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

      def []=(key, val)
        local[key] = val
      end

      def method_missing(key, *args)
        if key.to_s =~ /=$/
          key = key.to_s.gsub(/=$/, '').to_sym
          self[key] = args[0]
        else
          self[key]
        end
      end

      def local
        @@local ||= Configuration.new
      end
    end
  end
end

