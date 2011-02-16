# encoding: UTF-8

require 'hwia'

module Spontaneous
  class NamedSet

    include Enumerable


    def initialize(owner, name, supertype = nil)
      @owner, @name, @supertype = owner, name, supertype
      @superset = supertype.send(name) if supertype && supertype.respond_to?(name)
      @names = []
      @store = StrHash.new
      @order = nil
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
        yield named(name) if block_given?
      end
    end

    def names
      return @order if @order
      (@superset ? @superset.names : []) + @names
    end

    def named(name)
      if @store.key?(name)
        @store[name]
      elsif @superset
        @superset[name]
      else
        nil
      end
    end

    def set_order(new_order)
      @order = new_order
    end

    def last
      named(names.last)
    end

    def [](*args)
      if args.length == 1
        get_indexed(args[0])
      else
        args.map { |index| get_indexed(index) }.flatten
      end
    end

    def get_indexed(index)
      case index
      when String, Symbol
        named(index)
      when Range
        names[index].map { | name | named(name) }
      else
        named(names[index])
      end
    end

    def length
      names.length
    end

    alias_method :count, :length

    def empty?
      names.empty?
    end

    def to_hash
      self.map { |item| item.to_hash }
    end
  end
end


