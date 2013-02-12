require 'forwardable'

module Spontaneous
  class Config

    class Loader
      attr_reader :settings

      def self.read(settings, file, mode)
        self.new(settings, file, mode).load
      end

      def initialize(settings, file = nil, mode = nil)
        @settings, @file, @mode = settings, file, mode
      end

      def load
        instance_eval(File.read(@file)) if @file
        @settings
      end


      def back(&block)
        __mode__(:back, &block)
      end

      def front(&block)
        __mode__(:front, &block)
      end

      def __mode__(mode, &block)
        if @mode == mode
          yield if block_given?
        end
      end

      def method_missing(parameter, *args, &block)
        setting = args
        if args.length == 1
          setting = args[0]
          if block_given?
            key_name = setting
            setting = @settings[parameter] || {}
            values = setting[key_name] || {}
            block.call(values)
            setting.update({ key_name => values })
          end
        end
        @settings[parameter] = setting
      end
    end

    class Configuration
      extend ::Forwardable

      def initialize(settings = nil)
        @settings = {}
        merge!(settings) if settings
      end

      def merge!(hash)
        hash.each do |key, value|
          add_setting(key, value)
        end
      end

      def []=(key, value)
        add_setting(key, value)
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
            # Config.base[key]
            nil
          end
        end
      end

      def_delegators :@settings, :key?
    end

    DEFAULTS = {
    }.freeze unless defined?(DEFAULTS)

    attr_reader :environment, :mode, :env, :base, :local, :defaults

    def initialize(environment=:development, mode=:back)
      @environment = environment.to_sym
      @mode = mode
      @local = Configuration.new
      @env = Configuration.new
      @base = Configuration.new
      @defaults = Configuration.new(DEFAULTS)
    end

    def load(config_root)
      default = File.join(config_root, 'environment.rb')
      merge_file(default, @base)
      file =  File.join(config_root, "environments/#{environment}.rb")
      merge_file(file, @env)
    end

    def merge_file(path, configuration)
      store = Hash.new
      Loader.read(store, path, mode) if File.exist?(path)
      configuration.merge!(store)
    end

    def [](key)
      if local.key?(key)
        local[key]
      elsif env.key?(key)
        env[key]
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
  end
end

