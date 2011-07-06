# encoding: UTF-8

require 'hwia'

module Spontaneous
  class NamedSet < PrototypeSet


    # def initialize(owner, name, supertype = nil)
    #   super(supertype, name)
    #   @owner = owner
    # end

    # def push(item)
    #   push_named(item.name, item)
    #   @ids[item.schema_id] = item.name
    # end

    # def push_with_name(item, name)
    #   push_named(name, item)
    #   @ids[item.schema_id] = name
    # end

    # alias_method :<<, :push


    # def push_named(name, item)
    #   name = name.to_sym
    #   @store[name] = item
    #   @names.push(name)
    # end

    # protected :push_named

    # def key?(name)
    #   @store.key?(name)
    # end

    # def each
    #   names.each do |name|
    #     yield named(name) if block_given?
    #   end
    # end

    # def names
    #   return @order if @order
    #   (@superset ? @superset.names : []) + @names
    # end

    # def named(name)
    #   if @ids.key?(name)
    #     name = @ids[name]
    #   end
    #   if @store.key?(name)
    #     @store[name]
    #   elsif @superset
    #     @superset[name]
    #   else
    #     nil
    #   end
    # end

    # def set_order(new_order)
    #   @order = new_order
    # end

    # def last
    #   named(names.last)
    # end

    alias_method :get_without_ranges, :[]

    def [](*args)
      if args.length == 1
        get_single(args[0])
      else
        args.map { |index| get_indexed(index) }.flatten
      end
    end

    def get_single(index)
      case index
      when Range
        order[index].map { | name | named(name) }
      else
        get_without_ranges(index)
      end
    end

    # def length
    #   names.length
    # end

    # alias_method :count, :length

    # def empty?
    #   names.empty?
    # end

    def to_hash
      self.map { |item| item.to_hash }
    end
  end
end


