# encoding: UTF-8


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

      def [](name)
        slot = target[name] || create_slot(name)
      end

      def create_slot(name)
        owner.class.slots.create_slot_named(owner, name)
      end

      def method_missing(method, *args)
        if block_given?
          target.send(method, *args, &Proc.new)
        else
          target.send(method, *args)
        end
      end

    end # Slot Proxy
  end
end
