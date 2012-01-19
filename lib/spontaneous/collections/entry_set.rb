# encoding: UTF-8


module Spontaneous::Collections
  class EntrySet
    extend  Forwardable
    include Enumerable

    attr_reader :owner, :store


    def_delegators :@store, :each, :[], :index, :<<, :length, :last

    def initialize(owner, piece_store = [])
      @owner = owner
      @store = []
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
        @store << entry if entry
      end
    end

    def for_box(box)
      sid = box.schema_id
      store.select { |e| e.box_sid == sid }
    end

    def insert(index, piece)
      # piece.piece_store = self

      # puts "array_insert #{piece.serialize_db} => #{index}"
      # p serialize_db
      store.insert(index, piece)
      # p serialize_db
      owner.entry_modified!(piece)
    end


    def destroy!
      self.destroy
      owner.entry_modified!(nil)
    end

    def destroy
      store.dup.each { |e| e.destroy(false) }
    end

    def remove(piece)
      delete(piece)
    end


    def delete(piece)
      e = store.delete(piece)
      owner.entry_modified!(nil)
    end

    def serialize_db
      store.map { |e| e.serialize_db }
    end


    def set_position(content, position)
      piece = store.detect {|e| e.id == content.id }
      store.delete(piece)
      store.insert(position, piece)
      owner.entry_modified!(piece)
    end

    def export
      store.map do | piece |
        piece.export
      end
    end

    def freeze
      super
      store.freeze
      self
    end

    # Returns a frozen version of this set containing only entries that are visible
    def visible!
      entries = store.dup.reject { |e|  e.nil? || e.hidden? }
      # In 1.9.3 #reject does not return this subclass of Array but instead
      # returns a direct Array instance
      set = EntrySet.new(owner)
      set.concat(entries).freeze
      set
    end

    def ==(set)
      super or store == set
    end

    protected

    def concat(entries)
      store.concat(entries)
      self
    end
  end
end
