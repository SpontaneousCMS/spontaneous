# encoding: UTF-8


module Spontaneous::Collections
  class EntrySet < Array
    alias_method :array_insert, :insert
    alias_method :array_push,   :push
    alias_method :array_delete, :delete

    attr_reader :owner

    def initialize(owner, piece_store)
      @owner = owner
      (piece_store || []).each do |data|
        id = data[0]
        entry = \
          if data.length == 2
            page = @owner._pieces.detect { |piece| piece.id == id }
            Spontaneous::PagePiece.new(@owner, page, data[1])
          else
            @owner._pieces.detect { |piece| piece.id == id }
          end
        # if the piece/page has been deleted or is invisible
        # then we just want to silently skip it
        array_push(entry) if entry
      end
    end

    def for_box(box)
      sid = box.schema_id
      self.select { |e| e.box_sid == sid }
    end

    def insert(index, piece)
      # piece.piece_store = self
      array_insert(index, piece)
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
      e = array_delete(piece)
      owner.entry_modified!(nil)
    end

    def serialize_db
      self.map { |e| e.serialize_db }
    end


    def set_position(content, position)
      piece = self.detect {|e| e.id == content.id }
      self.array_delete(piece)
      self.insert(position, piece)
      owner.entry_modified!(piece)
    end

    def export
      map do | piece |
        piece.export
      end
    end

    def visible!
      self.dup.reject { |e| e.nil? or e.hidden? }.freeze
    end

  end
end
