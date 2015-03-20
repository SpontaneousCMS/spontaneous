# encoding: UTF-8

module Spontaneous::Model::Core
  module Boxes
    extend Spontaneous::Concern

    module ClassMethods
      def box(name, options = {}, &block)
        name = name.to_sym
        prototype = nil
        options[:group] = @box_group if @box_group

        # Because of load conflicts types are likely to be loaded twice
        return if box?(name, false)

        if existing_prototype = boxes[name]
          prototype = existing_prototype.merge(self, options, &block)
        else
          prototype = Spontaneous::Prototypes::BoxPrototype.new(self, name, options, &block)
        end

        box_prototypes[name] = prototype

        unless method_defined?(name)
          class_eval <<-BOX
            def #{name}
              boxes[:#{name}]
            end
          BOX
        end
        prototype
      end

      def boxes
        box_prototypes
      end

      def box_prototypes
        @box_prototypes ||= Spontaneous::Collections::PrototypeSet.new(superclass, :box_prototypes)
      end

      def has_boxes?
        !box_prototypes.empty?
      end

      def box_order(*new_order)
        box_prototypes.order = new_order.flatten
      end

      def box?(box_name, inherited = true)
        box_prototypes.key?(box_name.to_sym, inherited)
      end

      def is_box?
        false
      end

      def box_group(name, &block)
        @box_group = name #box_groups[name.to_sym]
        yield if block_given?
      ensure
        @box_group = nil
      end

      def box_position(box_prototype)
        box_prototypes.index(box_prototype)
      end
    end # ClassMethods

    # InstanceMethods

    def reload
      boxes.reload
      super
    end

    def boxes(*args)
      @boxes ||= Spontaneous::Collections::BoxSet.new(self)
    end

    # Used by #content_hash to attempt to preserve content hashes across
    # schema changes
    def boxes_with_consistent_order
      boxes.sort { |b1, b2| b1.schema_id <=> b2.schema_id }
    end

    def pieces
      boxes.flat_map { |b| b.pieces }
    end

    def iterable
      boxes
    end


    def box?(box_name)
      self.class.box?(box_name.to_sym)
    end

    def box_data(box)
      # TODO: use schema id to retrieve box data
      box_id = box.schema_id.to_s
      (self.box_store || []).detect { |data| data[:box_id] == box_id } || {}
    end

    def box_field_store(box)
      box_data(box)[:fields]
    end

    def box_modified!(modified_box)
      self.box_store = serialize_boxes
    end

    def serialize_boxes
      boxes.map { |box| box.serialize_db }
    end

    def box_style_id(box_name)
      nil
    end
  end
end
