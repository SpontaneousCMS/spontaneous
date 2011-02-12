# encoding: UTF-8

module Spontaneous::Plugins
  module Boxes
    module ClassMethods
      def box(name, options = {})
        boxes.push(Spontaneous::BoxPrototype.new(name, options))
        unless method_defined?(name)
          class_eval <<-BOX
            def #{name}
              boxes[:#{name}]
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
      def boxes(*args)
        @boxes ||= instantiate_boxes
      end

      def instantiate_boxes
        boxes = Spontaneous::NamedSet.new(self, :boxes)
        self.class.boxes.each do | box_prototype |
          boxes.push_named(box_prototype.name, box_prototype.get_instance(self))
        end
        boxes
      end
    end
  end
end

