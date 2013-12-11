# encoding: UTF-8

module Spontaneous::Collections
  class PrototypeSet
    include Enumerable

    attr_reader :store, :local_order

    def initialize(superobject = nil, superset_name = nil, &default_proc)
      @superobject, @superset_name = superobject, superset_name
      @has_superset = !!(@superobject && @superobject.respond_to?(@superset_name))
      @store = Hash.new
      @default_proc = default_proc
      @local_order = []
    end

    def []=(name, value)
      key = name.to_sym
      @store[key] = value
      add_key(key)
    end

    def [](key)
      case key
      when Fixnum
        indexed(key)
      else
        named(key)
      end
    end

    def add_key(key)
      local_order << key unless order.include?(key)
    end

    def key?(key, inherited = true)
      keys(inherited).include?(key.to_sym)
    end

    alias_method :has_key?, :key?

    def empty?
      order.empty?
    end

    def length
      order.length
    end

    alias_method :count, :length

    def last
      named(order.last)
    end

    def local_first
      if (key = local_order.first)
        named(key)
      else
        superset? ? superset.local_first : nil
      end
    end

    def hierarchy_detect(&block)
      if (found = local_detect(&block))
        found
      else
        superset? ? superset.hierarchy_detect(&block) : nil
      end
    end

    def local_detect(&block)
      local_values.detect(&block)
    end

    def local_values
      local_order.map { |name| named(name) }
    end

    def sid(schema_id)
      values.detect { |e| e.schema_id == schema_id }
    end

    def each
      order.each do |name|
        yield(named(name)) if block_given?
      end
    end

    def keys(inherited = true)
      order(inherited).map { |name| name }
    end

    def values
      map { | value | value }
    end

    # overwrites the existing ordering with a custom one
    # any current keys not explicitly included in the new ordering
    # will be tacked on the end in their current arrangement
    #
    # e.g.
    # set.order #=> [:a, :b, :c, :d]
    # set.order = [:b, :d]
    # set.order #=> [:b, :d, :a, :c]
    #
    def order=(newlocal_order)
      # clear any previous custom order
      @custom_order = nil
      oldlocal_order = order.dup
      order = []
      newlocal_order.each do |name|
        key = name.to_sym
        if oldlocal_order.include?(key)
          oldlocal_order.delete(key)
          order << key
        end
      end
      order += oldlocal_order
      @custom_order = order
    end


    def order(inherited = true)
      return @custom_order if @custom_order
      return local_order unless inherited
      superset? ? (superset.order + local_order) : local_order
    end

    alias_method :names, :order

    def indexed(index)
      named(order[index])
    end

    def named(name)
      key = name.to_sym
      return @store[key] if @store.key?(key)
      value = (superset? ? superset.named(name) : nil)
      return value unless value.nil?
      if @default_proc
        @default_proc.call(self, key)
      else
        nil
      end
    end

    def index(entry)
      order.index(entry.name)
    end

    def superset?
      @has_superset
    end

    # returns the superset for this set, if it exists
    # initialised lazily to avoid potential loops
    def superset
      @superset ||= @superobject.send(@superset_name) if superset?
    end



    def method_missing(method, *args)
      if key?(method)
        named(method)
      else
        super
      end
    end

    protected :local_order, :method_missing

  end # PrototypeSet
end # Spontaneous
