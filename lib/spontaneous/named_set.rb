# encoding: UTF-8

require 'hwia'

module Spontaneous
  class NamedSet

    include Enumerable


    def initialize(owner, name, supertype = nil)
      @owner, @name, @supertype = owner, name, supertype
      @superset = supertype.send(name) if supertype
      @names = []
      @store = StrHash.new
    end

    def push(item)
      push_named(item.name, item)
    end

    alias_method :<<, :push

    def push_named(name, item)
      name = name.to_sym
      @store[name] = item
      @names.push(name)
    end

    def each
      names.each do |name|
        yield get_named(name) if block_given?
      end
    end

    def names
      (@superset ? @superset.names : []) + @names
    end

    def get_named(name)
      if @store.key?(name)
        @store[name]
      elsif @superset
        @superset[name]
      else
        nil
      end
    end

    def last
      get_named(names.last)
    end

    def [](index)
      case index
      when String, Symbol
        get_named(index)
      else
        get_named(names[index])
      end
    end

    def length
      names.length
    end

    alias_method :count, :length

    def empty?
      names.empty?
    end

  end
end


