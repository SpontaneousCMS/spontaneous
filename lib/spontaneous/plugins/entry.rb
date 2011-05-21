# encoding: UTF-8

module Spontaneous::Plugins
  module Entry
    module InstanceMethods


      def box_id
        self[:box_id].to_sym
      end

      def box
        container.boxes.named(box_id) if container
      end

      def first?
        container.pieces.first == self
      end

      def last?
        container.pieces.last == self
      end

      def set_position(new_position)
        if box
          box.set_position(self, new_position)
        else
          container.pieces.set_position(self, new_position)
        end
      end

      def position
        container.pieces.index(self)
      end

      def serialize_entry
        { :piece => self.id }
      end
    end # InstanceMethods
  end # Entry
end # Spontaneous::Plugins

