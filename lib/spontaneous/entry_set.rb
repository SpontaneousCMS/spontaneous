
module Spontaneous
  class EntrySet < Array
    alias_method :store_insert, :insert
    alias_method :store_push, :push

    def initialize(owner, property_name)
      @owner = owner
      @property_name = property_name

      # entry_store.each do |data|
      #   klass = Spontaneous.const_get(data[:class])
      #   store_push( klass.new(@owner, data[:id], data[:style]) )
      # end

      slot_map = {}
      unmapped = []

      entry_store.each do |data|
        klass = Spontaneous.const_get(data[:class])
        entry = klass.new(@owner, data[:id], data[:style])
        if data[:slot]
          slot_map[data[:slot].to_sym] = entry
        else
          unmapped << entry
        end
      end

      @owner.class.slots.ordered_slots.each do |slot|
        store_push(slot_map[slot.name]) if slot_map[slot.name]
      end

      # append entries without corresponding slots to end
      unmapped.each do |entry|
        store_push(entry)
      end
    end

    def entry_store
      @owner.send(@property_name) || []
    end


    def insert(index, entry)
      entry.entry_store = self
      store_insert(index, entry)
      update!
    end

    def update!
      # p self.map { |e| e.serialize }
      @owner.set_all(@property_name => self.map { |e| e.serialize })
    end


    # def set_position(content, position)
    #   entry = self.detect {|e| e.target == content }
    #   self.delete(entry)
    #   self.insert(position, entry)
    #   @owner.entry_modified!(entry)
    # end

  end
end
