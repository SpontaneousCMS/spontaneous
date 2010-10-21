
module Spontaneous::Plugins
  module Slots
    class SlotSet < Spontaneous::ProxyObject
      attr_reader :owner

      def initialize(owner)
        @owner = owner
      end

      def tagged(tag)
        slots = owner.class.slots.tagged(tag.to_sym)
        slots.map { |s| self[s.name] }
      end

      def push(slot)
        owner.push(slot.get_instance)
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
