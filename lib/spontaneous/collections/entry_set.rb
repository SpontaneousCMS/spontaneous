# encoding: UTF-8


module Spontaneous::Collections
  class EntrySet
    include Enumerable

    attr_reader  :owner, :store, :length

    def initialize(owner, piece_store = [])
      @owner = owner
      @loaded = false
      @piece_store = piece_store || []
    end

    def store
      @store ||= initialize_store
    end

    # Lazily load the entries as it's not unlikely that we'll be loading instances
    # without ever wanting to access their contents
    def initialize_store
      store = Hash.new { |hash, key| hash[key] = [] }
      @piece_store.each do |data|
        id = data[0]
        entry = if (content = @owner._pieces.detect { |piece| piece.id == id })
          content.page? ? Spontaneous::PagePiece.new(@owner, content, data[1]) : content
        end
        # if the piece/page has been deleted or is invisible
        # then we just want to silently skip it
        if entry
          box_id =  entry.box_sid.to_s
          store[box_id] << entry
        end
      end
      @loaded = true
      store
    end

    def wrap_page(page)
      case @loaded
      when true
        find { |e| e.id == page.id }
      else
        quick_wrap_page(page)
      end
    end

    # Wrap a page with an entry without loading the owning item's content
    # association see Page#render_inline for a use case.
    #
    # We might be loading an individual page using its id and then trying to
    # render it immediately, in which case having to load the entire '_pieces'
    # association just to render a single page entry would be insane.
    #
    def quick_wrap_page(page)
      data = @piece_store.detect { |data|
        data[0] == page.id
      }
      return nil if data.nil?
      Spontaneous::PagePiece.new(@owner, page, data[1])
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

    # TODO: replace this with optimized version that can return a list of
    # ids for a particular box without loading the box's content
    def ids(box)
      for_box(box).map(&:id)
    end

    def insert(index, box, entry)
      box_id = box.schema_id.to_s
      store[box_id].insert(index, entry)
      owner.entry_modified!(entry)
    end

    # Called after the modification of box contents to keep the
    # raw data in-sync with the owner's structure
    def update(piece_store)
      @piece_store = piece_store
    end

    def destroy!
      self.destroy
      owner.entry_modified!(nil)
    end

    def destroy(origin)
      store.each do |box_id, entries|
        entries.dup.each { |e| e.destroy(false, origin) }
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
      # freeze the entries first in order to ensure that we've loaded our entries
      # before freezing ourself
      store.values.each { |entries| entries.freeze }
      super
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
      super || (entries == set)
    end

    protected

    def concat(box_id, entries)
      store[box_id].concat(entries)
      self
    end
  end
end
