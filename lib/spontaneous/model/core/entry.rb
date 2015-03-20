# encoding: UTF-8

module Spontaneous::Model::Core
  module Entry
    extend Spontaneous::Concern

    # InstanceMethods

    # kept to allow access to pages & pieces as they would be seen when
    # accessed as an entry in a box
    def entry
      self
    end

    # Used by boxes to place this item in the content hierarchy
    def to_entry(container, position)
      @box, @position = container, position
      self
    end

    def box_sid
      @box_sid ||= mapper.schema_uid(self[:box_sid])
    end

    def box_sid=(sid)
      self[:box_sid] = sid.to_s
    end

    def box
      @box ||= owner.try { |o| o.boxes.sid(box_sid) }
    end

    def container
      box
    end

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
      box.set_position(self, new_position)
      @position = new_position
      save
    end

    def position
      return @position unless @position.nil?
      return 0 if owner.nil? # special case for root
      @position ||= container.index(self)
    end
  end # Entry
end # Spontaneous::Plugins
