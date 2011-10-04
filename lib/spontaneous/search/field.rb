# encoding: UTF-8

module Spontaneous::Search
  class Field
    attr_reader :prototype, :options

    def initialize(prototype, options)
      @prototype = prototype
      @options = options
    end

    def in_index?(index)
      indexes.any? { |opts| opts[:index] == index }
    end

    def index_id(index)
      opts = options_for_index(index)
      opts[:group] || prototype.schema_id.to_s
    end

    def options_for_index(index)
      indexes.detect { |opts| opts[:index] == index }
    end

    def field_definition(index)
      defn = {:type => String, :store => true, :weight => 1, :index => true}
      opts = options_for_index(index)
      case opts[:weight]
      when :store
        defn.merge!({
          :index => false,
          :store => true
        })
      when Fixnum
        defn.merge!({
          :weight => opts[:weight]
        })
      else
        # check for symbol shortcuts to weight
      end
      defn
    end

    def indexes
      @indexes ||= parse_indexes(options)
    end

    def parse_indexes(opts)
      case opts
      when  true
        S::Site.indexes.values.map { |index| default_index_options(index) }
      when Symbol
        index = find_index(opts)
        logger.warn("Invalid index :#{opts}") unless index
        [default_index_options(index)]
      when Hash
        [ opts.merge(:index => find_index(opts[:name])) ]
      when Array
        opts.map { |o| parse_indexes(o) }.flatten
      else
        []
      end
    end

    def default_index_options(index)
      index_options(index)
    end

    def index_options(index, weight = 1, group = nil)
      {:name => index.name, :index => index, :weight => weight, :group => group}
    end

    def find_index(name)
      S::Site.indexes[name]
    end
  end
end
