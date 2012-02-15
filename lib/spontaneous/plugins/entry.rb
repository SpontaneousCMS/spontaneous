# encoding: UTF-8

module Spontaneous::Plugins
  module Entry
    extend ActiveSupport::Concern

    # InstanceMethods

    # kept to allow access to pages & pieces as they would be seen when
    # accessed as an entry in a box
    def entry
      self
    end

    def box_sid
      @box_sid ||= Spontaneous.schema.uids[self[:box_sid]]
    end

    def box_sid=(sid)
      self[:box_sid] = sid.to_s
    end

    def box
      owner.boxes.sid(box_sid) if owner
    end

    alias_method :container,  :box

    def first?
      container.contents.first == self
    end

    def last?
      container.contents.last == self
    end

    def next
      return nil if last?
      container.contents[position + 1]
    end

    def previous
      return nil if first?
      container.contents[position - 1]
    end

    alias_method :prev, :previous

    def set_position(new_position)
      if box
        box.set_position(self, new_position)
      else
        owner.pieces.set_position(self, new_position)
      end
    end

    def position
      return box.index(self) if box
      owner.pieces.index(self)
    end

    def serialize_db
      [self.id]
    end
  end # Entry
end # Spontaneous::Plugins
