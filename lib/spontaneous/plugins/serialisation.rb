# encoding: UTF-8


module Spontaneous::Plugins
  module Serialisation

    module ClassMethods
      def export
        {
          :type=> self.json_name,
          :id => self.schema_id.to_s,
          :is_page => self.page?,
          :is_alias => self.alias?,
          :title=> self.title,
          :fields => readable_fields.map { |name| field_prototypes[name].export },
          :styles => readable_styles.map { |style| style.export },
          :boxes => readable_boxes.map { |box| box.export },
          :source => self.__source_file
        }
      end

      def readable_styles
        styles
      end

      def readable_boxes
        boxes.select { |box| box.readable? }
      end

      def readable_fields
        field_names.select { |name| field_readable?(name) }
      end

      def to_json
        export.to_json
      end

    end # ClassMethods

    module InstanceMethods
      def shallow_export
        {
          :id => id,
          :type => self.class.json_name,
          :type_id => self.class.schema_id.to_s,
          :is_page => page?,
          :hidden => (hidden? ? true : false),
          :depth => content_depth,
          :fields  => fields.export,
          :label => label
        }
      end

      def export
        shallow_export.merge({
          :boxes => self.class.readable_boxes.map { |box| boxes[box.name].export }
        })
      end


      def to_json
        export.to_json
      end
    end # InstanceMethods
  end # Serialisation
end # Spontaneous::Plugins

