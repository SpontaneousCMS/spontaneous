# encoding: UTF-8

module Spontaneous::Plugins
  module Boxes
    module ClassMethods
      def box(name, options = {})
        boxes.push(Spontaneous::BoxPrototype.new(name, options))
        unless method_defined?(name)
          class_eval <<-BOX
            def #{name}
              boxes.named(:#{name})
            end
          BOX
        end
      end

      def boxes(*args)
        @boxes ||= Spontaneous::NamedSet.new(self, :boxes, superclass)
      end

      def has_boxes?
        !boxes.empty?
      end

      def box_order(*new_order)
        new_order.flatten!
        boxes.set_order(new_order)
      end
    end

    module InstanceMethods
      def reload
        @boxes = nil
        super
      end

      def boxes(*args)
        @boxes ||= instantiate_boxes
      end

      def instantiate_boxes
        boxes = Spontaneous::NamedSet.new(self, :boxes)
        self.class.boxes.each do | box_prototype |
          box = box_prototype.get_instance(self)
          boxes.push_named(box_prototype.name, box)
        end
        boxes
      end

      def box_data(box_name)
        # TODO: use schema id to retrieve box data
        (self.box_store || []).detect { |data| data[:box_id] = box_name } || {}
      end

      def box_field_store(box_name)
        box_data(box_name)[:fields]
      end

      def box_modified!(modified_box)
        self.box_store = serialize_boxes
      end

      def serialize_boxes
        boxes.map { |box| box.serialize }
      end

      def box_style_id(box_name)
        nil
      end

      def entries_for_box(box)
        p self.pieces
        p self.entries
      end
    end
  end
end

