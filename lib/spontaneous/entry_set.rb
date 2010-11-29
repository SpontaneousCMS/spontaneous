# encoding: UTF-8


module Spontaneous
  class EntrySet < Array
    alias_method :store_insert, :insert
    alias_method :store_push, :push

    attr_reader :owner

    def initialize(owner, entry_store)
      @owner = owner
      @name_map = {}

      slot_map = {}
      unmapped = []

      (entry_store || []).each do |data|
        klass = Spontaneous.const_get(data[:type])
        entry = klass.new(@owner, data[:id], data[:style])
        if data[:slot]
          slot_map[data[:slot].to_sym] = entry
        else
          unmapped << entry
        end
      end

      @owner.class.slots.ordered_slots.each do |slot|
        if e = slot_map[slot.name]
          store_push(e)
        end
      end

      # append entries without corresponding slots to end
      unmapped.each do |entry|
        store_push(entry)
      end
    end

    def push(entry)
      super(entry)
      @name_map[entry.name.to_sym] = entry unless (entry.name.nil? or entry.name.empty?)
    end

    alias_method :<<, :push

    def [](index)
      case index
      when Symbol, String
        labelled(index.to_sym)
      else
        super
      end
    end

    def labelled(label)
      label = label.to_sym
      find { |e| e.label == label }
    end

    def insert(index, entry)
      entry.entry_store = self
      store_insert(index, entry)
      @owner.entry_modified!(entry)
    end


    def destroy!
      self.destroy
      @owner.entry_modified!(nil)
    end

    def destroy
      self.dup.each { |e| e.destroy(false) }
    end

    def remove(entry)
      e = self.delete(entry)
      @owner.entry_modified!(nil)
    end

    def serialize
      self.map { |e| e.serialize }
    end


    def set_position(content, position)
      entry = self.detect {|e| e.target == content }
      self.delete(entry)
      self.insert(position, entry)
      @owner.entry_modified!(entry)
    end

    def to_hash
      map do | entry |
        entry.to_hash
      end
    end

    protected

    def method_missing(method, *args, &block)
      if entry = labelled(method)
        entry
      else
        super
      end
    end
  end
end
