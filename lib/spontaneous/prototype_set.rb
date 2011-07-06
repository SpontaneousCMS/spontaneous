# encoding: UTF-8

module Spontaneous
  class PrototypeSet
    include Enumerable

    attr_reader :store

    def initialize(superobject = nil, superset_name = nil)
      @superobject, @superset_name = superobject, superset_name
      @has_superset = !!(@superobject && @superobject.respond_to?(@superset_name))
      @store = {}
      @order = []
    end

    def []=(name, value)
      key = name.to_sym
      @store[key] = value
      @order << key unless order.include?(key)
    end

    def [](key)
      case key
      when Fixnum
        indexed(key)
      else
        named(key)
      end
    end

    def key?(key)
      keys.include?(key.to_sym)
    end

    alias_method :has_key?, :key?

    def sid(schema_id)
      values.detect { |e| e.schema_id == schema_id }
    end

    def each
      order.each do |name|
        yield(named(name)) if block_given?
      end
    end

    def keys
      order.map { |name| name }
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
    def order=(new_order)
      # clear any previous custom order
      @custom_order = nil
      old_order = order.dup
      order = []
      new_order.each do |name|
        key = name.to_sym
        if old_order.include?(key)
          old_order.delete(key)
          order << key
        end
      end
      order += old_order
      @custom_order = order
    end


    def order
      return @custom_order if @custom_order
      superset? ? (superset.order + @order) : @order
    end

    alias_method :names, :order

    protected

    def indexed(index)
      named(order[index])
    end

    def named(name)
      @store[name.to_sym] || (superset? ? superset.named(name) : nil)
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
  end # PrototypeSet
end # Spontaneous
