# encoding: UTF-8


module Spontaneous::Collections
  class EntrySet
    include Enumerable

    attr_reader  :owner, :store, :length

    def initialize(owner, piece_store = [])
      @owner = owner
      @store = Hash.new { |hash, key| hash[key] = [] }
      (piece_store || []).each do |data|
        id = data[0]
        entry = \
          if data.length == 2
            page = @owner._pieces.detect { |piece| piece.id == id }
            if page
              Spontaneous::PagePiece.new(@owner, page, data[1])
            else
              nil
            end
          else
            @owner._pieces.detect { |piece| piece.id == id }
          end
        # if the piece/page has been deleted or is invisible
        # then we just want to silently skip it
        if entry
          box_id =  entry.box_sid.to_s
          @store[box_id] << entry
        end
      end
    end

    def each(&block)
      owner.boxes.each do |box|
        store[box.schema_id.to_s].each(&block)
      end
    end

    def last
      owner.boxes.last.last
    end

    def length
      store.values.inject(0) { |sum, e| sum += e.length }
    end

    alias_method :size, :length

    def for_box(box)
      sid = box.schema_id.to_s
      store[sid]
    end

    def insert(index, box, entry)
      box_id = box.schema_id.to_s
      store[box_id].insert(index, entry)
      owner.entry_modified!(entry)
    end


    def destroy!
      self.destroy
      owner.entry_modified!(nil)
    end

    def destroy
      store.each do |box_id, entries|
        entries.dup.each { |e| e.destroy(false) }
      end
    end

    def remove(piece)
      delete(piece)
    end


    def delete(entry)
      box_id = entry.box_sid.to_s
      e = store[box_id].delete(entry)
      owner.entry_modified!(nil)
    end

    def serialize_db
      self.map { |e| e.serialize_db }
    end


    def set_position(content, position)
      entries = store[content.box_sid.to_s]
      piece = entries.detect {|e| e.id == content.id }
      entries.delete(piece)
      entries.insert(position, piece)
      owner.entry_modified!(piece)
    end

    def export
      self.map do | piece |
        piece.export
      end
    end

    def freeze
      super
      store.values.each { |entries| entries.freeze }
      self
    end

    # Returns a frozen version of this set containing only entries that are visible
    def visible!
      set = EntrySet.new(owner)
      store.each do |box_id, entries|
        visible = entries.reject { |e|  e.nil? || e.hidden? }
        set.concat(box_id, visible)
      end
      set.freeze
    end

    def ==(set)
      super or entries == set
    end

    protected

    def concat(box_id, entries)
      store[box_id].concat(entries)
      self
    end
  end
end
