
module Spontaneous::Plugins
  module Slots
    class SlotSet < Spontaneous::ProxyObject
      attr_reader :owner

      def initialize(owner)
        @owner = owner
      end

      def group(group_name)
        slots = owner.class.slots.group(group_name.to_sym)
        slots.map { |s| self[s.name] }
      end

      def push(slot)
        facet = slot.instance_class.new(:type_id => Spontaneous::Facet, :label => slot.name, :slot_name => slot.title, :slot_id => slot.name )
        entry = owner.push(facet)
      end

      alias_method :<<, :push

      def target
        owner.entries
      end

      def method_missing(method, *args, &block)
        target.send(method, *args, &block)
      end

    end # Slot Proxy
  end
end
