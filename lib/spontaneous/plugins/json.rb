# encoding: UTF-8


module Spontaneous::Plugins
  module JSON

    module ClassMethods
      def to_hash
        {
          :type=> self.json_name,
          :title=> self.title,
          :fields => readable_fields.map { |name| field_prototypes[name].to_hash },
          :boxes => readable_boxes.map { |box| box.to_hash }
        }
      end

      def readable_boxes
        boxes.select { |box| box.readable? }
      end

      def readable_fields
        field_names.select { |name| field_readable?(name) }
      end

      def to_json
        to_hash.to_json
      end

    end # ClassMethods

    module InstanceMethods
      def to_shallow_hash
        {
          :id => id,
          :type => self.class.json_name,
          # :type_id => type.id,
          :is_page => page?,
          :depth => content_depth,
          :fields  => fields.to_hash,
          :name => slot_name,
          :label => label
        }
      end

      def to_hash
        to_shallow_hash.merge({
          :boxes => self.class.readable_boxes.map { |box| boxes[box.name].to_hash }
        })
      end


      def to_json
        to_hash.to_json
      end
    end # InstanceMethods
  end # JSON
end # Spontaneous::Plugins

