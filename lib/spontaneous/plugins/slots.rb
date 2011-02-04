# encoding: UTF-8


module Spontaneous::Plugins
  module Slots

    module ClassMethods
      def slot(name, options={}, &block)
        slot = Slot.new(self, name, options, &block)
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

      def schema_validate
        slots.each { |slot| slot.schema_validate }
      end
    end # ClassMethods

    module InstanceMethods
      def slots
        @slots ||= SlotSet.new(self)
      end

      def slot?(slot_name)
        self.class.slot?(slot_name.to_sym)
      end

      protected

      def after_initialize
        super
        verify_slots!
      end

      def verify_slots!
        unless @_slots_verified
          if new?
            self.class.slots.instantiate(self)
          else
            self.class.slots.verify(self)
          end
          @_slots_verified = true
        end
      end

      def after_save
        slots.each do |slot|
          slot.save if slot.modified?
        end
        super
      end


    end # InstanceMethods
  end # Slots
end # Spontaneous::Plugins
