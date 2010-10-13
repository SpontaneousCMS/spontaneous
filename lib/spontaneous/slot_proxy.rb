
module Spontaneous
  class SlotProxy < ProxyObject
    attr_reader :owner

    def initialize(owner)
      @owner = owner
      @map = {}
      load_slots
    end

    def [](slot_name)
      @map[slot_name.to_sym]
    end

    def group(group_name)
      slots = owner.class.slots.group(group_name.to_sym)
      slots.map { |s| self[s.name] }
    end

    def push(slot)
      facet = slot.instance_class.new(:label => slot.name, :slot_name => slot.title, :slug => slot.name )
      entry = owner.push(facet)
      @map[slot.name] = entry
    end

    def method_missing(method, *args, &block)
      slot_name = method.to_sym
      if @map.key?(slot_name)
        self[slot_name]
      else
        owner.entries.send(method, *args, &block)
      end
    end

    alias_method :<<, :push

    def load_slots
      owner.entries.each do |e|
        @map[e.label.to_sym] = e unless e.label.nil?
      end
    end
  end
end
