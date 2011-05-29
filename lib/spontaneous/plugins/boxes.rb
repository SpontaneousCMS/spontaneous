# encoding: UTF-8

module Spontaneous::Plugins
  module Boxes
    module ClassMethods
      def box(name, options = {}, &block)
        boxes.push(Spontaneous::BoxPrototype.new(self, name, options, &block))
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

      def box_prototypes
        Hash[@boxes.map { |p| [p.name, p] }]
      end

      def has_boxes?
        !boxes.empty?
      end

      def box_order(*new_order)
        new_order.flatten!
        boxes.set_order(new_order)
      end

      def box?(box_name)
        !boxes[box_name].nil?
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

      def iterable
        boxes
      end

      def box?(box_name)
        self.class.box?(box_name.to_sym)
      end

      def box_data(box)
        # TODO: use schema id to retrieve box data
        box_id = box.box_id.to_s
        (self.box_store || []).detect { |data| data[:box_id] == box_id } || {}
      end

      def box_field_store(box)
        box_data(box)[:fields]
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
    end
  end
end

