# encoding: UTF-8


module Spontaneous
  class EntrySet < Array
    alias_method :store_insert, :insert
    alias_method :store_push,   :push
    alias_method :store_delete, :delete

    attr_reader :owner

    def initialize(owner, piece_store)
      @owner = owner
      type_cache = Hash.new { |hash, key| hash[key] = Spontaneous.const_get(key) }

      (piece_store || []).each do |data|
        klass = type_cache[data[:type]]
        piece = klass.new(@owner, data[:id], data[:style], data[:box_id])
        store_push(piece)
      end
    end

    def for_box(box)
      box_id = box.box_id
      self.select { |e| e.box_id == box_id }
    end

    def insert(index, piece)
      piece.piece_store = self
      store_insert(index, piece)
      owner.entry_modified!(piece)
    end


    def destroy!
      self.destroy
      owner.entry_modified!(nil)
    end

    def destroy
      self.dup.each { |e| e.destroy(false) }
    end

    def remove(piece)
      delete(piece)
    end


    def delete(piece)
      e = store_delete(piece)
      owner.entry_modified!(nil)
    end

    def serialize
      self.map { |e| e.serialize }
    end


    def set_position(content, position)
      piece = self.detect {|e| e.target == content }
      self.store_delete(piece)
      self.insert(position, piece)
      owner.entry_modified!(piece)
    end

    def to_hash
      map do | piece |
        piece.to_hash
      end
    end

    def visible!
      self.dup.reject { |e| e.hidden? }.freeze
    end

  end
end
