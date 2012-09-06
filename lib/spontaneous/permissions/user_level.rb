# encoding: UTF-8

require 'yaml'

module Spontaneous::Permissions
  class UserLevel

    class Root
      private(:initialize)
      def self.>(level)     ; level < Root ; end
      def self.>=(level)    ; true  ; end
      def self.<=>(level)   ; 1     ; end
      def self.to_s         ; 'root'; end
      def self.to_sym       ; :root ; end
      def self.can_publish? ; true  ; end
      def self.developer?   ; true  ; end
      def self.admin?       ; true  ; end
    end

    class None
      private(:initialize)
      def self.>(level)     ; false ; end
      def self.>=(level)    ; level.equal?(None); end
      def self.<=>(level)   ; -1    ; end
      def self.to_s         ; 'none'; end
      def self.to_sym       ; :none ; end
      def self.can_publish? ; false ; end
      def self.developer?   ; false ; end
      def self.admin?       ; false ; end
    end

    class Level
      @@instances = Hash.new

      def self.[](value, description)
        name = description.delete(:name)
        if @@instances.key?(value.to_i)
          @@instances[value.to_i]
        else
          @@instances[value.to_i] = self.new(name, value.to_i, description)
        end
      end

      attr_reader  :name, :value
      alias_method :to_i, :value

      def initialize(name, value, permissions)
        @name, @value, @permissions = name.to_sym, value.to_i, permissions
      end

      def >(level)
        return false if level.equal?(Root)
        return true  if level.equal?(None)
        @value > level.to_i
      end

      def >=(level)
        return false if level.equal?(Root)
        return true  if level.equal?(None)
        @value >= level.to_i
      end

      def <(level)
        return true  if level.equal?(Root)
        return false if level.equal?(None)
        @value < level.to_i
      end

      def <=>(level)
        return -1 if level.equal?(Root)
        return  1 if level.equal?(None)
        @value <=> level.to_i
      end

      def ==(level)
        return false if level.equal?(Root)
        return false if level.equal?(None)
        return @value == level.to_i
      end

      def can_publish?
        @permissions[:publish] || false
      end

      def developer?
        @permissions[:developer] || false
      end

      # Users with admin level can access the user manager interface
      def admin?
        @permissions[:admin] || false
      end

      def to_s
        @name.to_s
      end

      def to_sym
        @name.to_sym
      end
    end

    class << self
      def minimum
        get(all[1]) || None
      end

      def [](level)
        get(level)
      end

      def get(level)
        store[level.to_sym]
      end

      def all(base_level = nil)
        list = store.values.sort { |a, b| a <=> b }
        list.reject! { |l| l > get(base_level) } if base_level
        list
      end

      def root
        Root
      end

      def none
        None
      end

      def level_file
        Spontaneous.root / 'config/user_levels.yml'
      end

      # def level_file=(file)
      #   @level_file = file
      # end

      def reset!
        @initialised = false
        @store = nil
      end

      def init!
        return if @initialised
        store[:none] = None
        store[:root] = Root
        numeric = 1
        if File.exists?(level_file)
          levels = YAML.load_file(level_file)
          levels.each_with_index do |description, index|
            level = Level[(index+1), description]
            store[level.name] = level
          end
        else
          logger.warn {
            "User level file '#{level_file}' missing, unable to load User Levels"
          }
        end
        @initialised = true
      end

      def store
        if !@store
          @store = Hash.new
          init!
        end
        @store
      end

      def method_missing(method, *args)
        if level = get(method)
          level
        else
          super
        end
      end
    end
  end
end

