
module Spontaneous::Plugins
  module Slots

    module ClassMethods
      def slot(name, options={})
        slot = Spontaneous::Slot.new(self, name, options)
        unless method_defined?(name)
          define_method(name) { slots[slot.name] }
        end
        slots << slot
      end

      def slots
        @slots ||= Spontaneous::SlotDefinitions.new(self)
      end

      def slot?(slot_name)
        !slots.detect {|s| s.name == slot_name }.nil? || (supertype ? supertype.slot?(slot_name) : false )
      end

      def slot_order(*order)
        @slot_order = order.flatten
      end

      def custom_slot_order
        @slot_order
      end

      def has_slots?
        !slots.empty?
      end
    end

    module InstanceMethods
      def slots
        @slots ||= Spontaneous::SlotProxy.new(self)
      end

      def slot?(slot_name)
        self.class.slot?(slot_name.to_sym)
      end
    end
  end
end
