# encoding: UTF-8

require 'hwia'
require 'yaml'

module Spontaneous
  class UserLevel

    class Root
      private(:initialize)
      def self.>(level); true; end
      def self.>=(level); true; end
      def self.<=>(level); 1; end
      def self.to_s; 'root'; end
    end

    class None
      private(:initialize)
      def self.>(level); false; end
      def self.>=(level); false; end
      def self.<=>(level); -1; end
      def self.to_s; 'none'; end
    end

    class Level
      @@instances = Hash.new

      def self.[](name, value)
        if @@instances.key?(value.to_i)
          @@instances[value.to_i]
        else
          @@instances[value.to_i] = self.new(name, value)
        end
      end

      attr_reader  :value
      alias_method :to_i, :value

      def initialize(name, value)
        @name, @value = name, value.to_i
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

      def to_s
        @name.to_s
      end
    end

    class << self
      def minimum
        get(all[1])
      end

      def [](level)
        get(level)
      end

      def get(level)
        init!
        store[level]
      end

      def all(base_level = nil)
        list = store.to_a.sort { |a, b| a[1] <=> b[1] }
        list.reject! { |l| l[1] > get(base_level) } if base_level
        list.map { |l| l[0] }
      end

      def root
        Root
      end

      def none
        None
      end

      def level_file
        @level_file ||= 'config/user_levels.yml'
      end

      def level_file=(file)
        @level_file = file
      end

      def init!
        return if @initialised
        store[:none] = None
        store[:root] = Root

        if File.exists?(level_file)
          levels = YAML.load_file(level_file)
          levels.each do |name, level|
            store[name] = Level[name, level]
          end
        else
          logger.warn {
            "User level file '#{level_file}' missing, unable to load User Levels"
          }
        end
        @initialised = true
      end

      def store
        @store ||= StrHash.new
      end

      def method_missing(method, *args, &block)
        if level = get(method)
          level
        else
          super
        end
      end
    end
  end
end

