# encoding: UTF-8

module Spontaneous::Search
  class Field
    attr_reader :prototype, :options

    # TODO: options seems redundant as its available as prototype.options
    def initialize(site, prototype, options)
      @site = site
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

    WEIGHTINGS = {
      :normal  => 1,
      :high    => 4,
      :higher  => 8,
      :highest => 16
    }.freeze unless defined?(WEIGHTINGS)

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
      when Symbol
        defn.merge!({
          :weight => WEIGHTINGS[opts[:weight]] || 1
        })
      end
      defn
    end

    def indexes
      @indexes ||= parse_indexes(options)
    end

    # convert the options passed to :index in a field definition to a list of
    # options. Each entry contains the index to which it pertains and then
    # the options that should be applied to this field within that index
    def parse_indexes(opts)
      all_indexes = @site.indexes.values
      case opts
      when  true
        all_indexes.map { |index| default_index_options(index) }
      when Symbol
        index = find_index(opts)
        [default_index_options(index)]
      when Hash
        if (index_name = opts[:name])
          [ opts.merge(:index => find_index(index_name)) ]
        else
          all_indexes.map { |index| default_index_options(index).merge(opts) }
        end
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
      index = @site.indexes[name]
      logger.warn("Invalid index :#{name} for field #{@prototype.owner}.#{@prototype.name}") unless index
      index
    end
  end
end
