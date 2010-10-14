
module Spontaneous::Plugins
  module Slots
    class SlotDefinitions < Spontaneous::ProxyObject
      def initialize(klass)
        @content_class = klass
        @store = []
        if @content_class.superclass.respond_to?(:slots)
          @store.concat(@content_class.superclass.slots)
        end
      end

      def map(&block)
        in_order(:map, &block)
      end

      alias_method :collect, :map

      def each(&block)
        in_order(:each, &block)
      end

      def in_order(method, &block)
        ordered_slots.send(method, &block)
      end

      def ordered_slots
        fo = @content_class.custom_slot_order
        if fo.nil? or fo.empty?
          @store
        else
          fo.map do |name|
            @store.detect { |slot| slot.name == name }
          end
        end
      end

      def instantiate(content)
        self.each do |slot|
          content.slots << slot
        end
      end

      def group(group_name)
        self.select { |s| s.group == group_name }
      end

      def verify(content)
        # if the class doesn't define any slots then just skip this
        return if @content_class.slots.length == 0
        defined_slots = @content_class.slots.length
        existing_entries = content.entries.length
        if defined_slots != existing_entries
          if defined_slots > existing_entries
            # easy, just add another entry for the slot
            remaining_slots = @content_class.slots.dup
            content.entries.each do |entry|
              remaining_slots.reject! { |s| s.name == entry.label.to_sym }
            end
            remaining_slots.each do |slot|
              content.slots.push(slot)
            end
          else
            # we have more entries than slots
            # we don't have any info about the slot that was removed
            # and we don't want to delete anything that was added by hand
            # so this is tricky
            # entries defined by slot defns have their slug attribute set
            # on creation. slug is not editable in the ui
            # so we can use it as a quick test for "slottiness"

            # find all facets that have a #slug defined that does not match with
            # a defined slot name and delete them
            orphan_slots = []
            content.entries.each do |entry|
              unless entry.slug.nil? or entry.slug.empty?
                # this entry was defined by a slot
                slot = @content_class.slots.find { |s| s.name.to_s == entry.slot_id }
                unless slot
                  puts "deleting entry #{entry.inspect}"
                end
              end
            end
          end
          content.save
        end
      end

      def method_missing(method, *args, &block)
        @store.send(method, *args, &block)
      end
    end # SlotDefinitions
  end # Slots
end # Spontaneous
