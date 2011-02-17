# encoding: UTF-8


module Spontaneous
  class EntrySet < Array
    alias_method :store_insert, :insert
    alias_method :store_push,   :push
    alias_method :store_delete, :delete

    attr_reader :owner

    def initialize(owner, entry_store)
      @owner = owner
      type_cache = Hash.new { |hash, key| hash[key] = Spontaneous.const_get(key) }

      (entry_store || []).each do |data|
        klass = type_cache[data[:type]]
        entry = klass.new(@owner, data[:id], data[:style], data[:box_id])
        store_push(entry)
      end
    end

    def for_box(box)
      box_id = box.box_id
      self.select { |e| e.box_id == box_id }
    end

    def insert(index, entry)
      entry.entry_store = self
      store_insert(index, entry)
      owner.entry_modified!(entry)
    end


    def destroy!
      self.destroy
      owner.entry_modified!(nil)
    end

    def destroy
      self.dup.each { |e| e.destroy(false) }
    end

    def remove(entry)
      delete(entry)
    end


    def delete(entry)
      e = store_delete(entry)
      owner.entry_modified!(nil)
    end

    def serialize
      self.map { |e| e.serialize }
    end


    def set_position(content, position)
      entry = self.detect {|e| e.target == content }
      self.store_delete(entry)
      self.insert(position, entry)
      owner.entry_modified!(entry)
    end

    def to_hash
      map do | entry |
        entry.to_hash
      end
    end

    def visible!
      self.dup.reject { |e| e.hidden? }.freeze
    end

  end
end
