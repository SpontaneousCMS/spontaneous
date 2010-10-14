
module Spontaneous::Plugins
  module Slots

    module ClassMethods
      def slot(name, options={})
        slot = Slot.new(self, name, options)
        unless method_defined?(name)
          define_method(name) { slots[slot.name] }
        end
        slots << slot
      end

      def slots
        @slots ||= SlotDefinitions.new(self)
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
    end # ClassMethods

    module InstanceMethods
      def after_initialize
        super
        if new?
          self.class.slots.instantiate(self)
        else
          self.class.slots.verify(self)
        end
      end

      def slots
        @slots ||= SlotProxy.new(self)
      end

      def slot?(slot_name)
        self.class.slot?(slot_name.to_sym)
      end
    end # InstanceMethods
  end # Slots
end # Spontaneous::Plugins
