# encoding: UTF-8


module Spontaneous
  class EntrySet < Array
    alias_method :array_insert, :insert
    alias_method :array_push,   :push
    alias_method :array_delete, :delete

    attr_reader :owner

    def initialize(owner, piece_store)
      @owner = owner
      (piece_store || []).each do |data|
        entry = \
          if data[:page]
            page = @owner._pieces.detect { |piece| piece.id == data[:page] }
            PagePiece.new(@owner, page, data[:style_id])
          else
            @owner._pieces.detect { |piece| piece.id == data[:piece] }
          end
        array_push(entry)
      end
    end

    def for_box(box)
      box_id = box.box_id
      self.select { |e| e.box_id == box_id }
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

    def serialize
      self.map { |e| e.serialize_entry }
    end


    def set_position(content, position)
      piece = self.detect {|e| e.id == content.id }
      self.array_delete(piece)
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
