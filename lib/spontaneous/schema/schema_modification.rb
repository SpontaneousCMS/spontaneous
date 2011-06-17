# encoding: UTF-8


module Spontaneous
  module Schema
    class SchemaModification
      def initialize(missing_from_map, missing_from_schema)
        @missing_from_map = missing_from_map
        @missing_from_schema = missing_from_schema
      end

      def select_missing(select_type)
        @missing_from_schema.select do |reference|
          reference.category == select_type
        end
      end

      def added_classes
        @missing_from_map[:class].map { |m| m[0] }.uniq
      end

      def removed_classes
        select_missing(:type)
      end

      def added_fields
        @missing_from_map[:field].map { |m| m[1] }.uniq
      end

      def removed_fields
        select_missing(:field)
      end

      def added_boxes
        @missing_from_map[:box].map { |m| m[1] }.uniq
      end

      def removed_boxes
        select_missing(:box)
      end

      def added_styles
        @missing_from_map[:style].map { |m| m[1] }
      end

      def removed_styles
        select_missing(:style)
      end

      def added_layouts
        @missing_from_map[:layout].map { |m| m[1] }
      end

      def removed_layouts
        select_missing(:layout)
      end

      def resolvable?
        only_added_items? or only_removed_items?
      end

      def only_added_items?
        if removed_items.empty?
          !added_items.empty?
        else
          false
        end
      end

      def only_removed_items?
        if removed_items.empty?
          false
        else
          added_items.empty?
        end
      end

      def resolve!
        if only_added_items?
          added_items.each do |obj|
            Spontaneous::Schema.generate_schema_for(obj)
          end
        end

        if only_removed_items?
          removed_items.each do |uid|
            uid.destroy
          end
        end
      end

      def added_items
        added = []
        [:classes, :fields, :boxes, :styles, :layouts].each do |category|
          added.concat(self.send("added_#{category}"))
        end
        added
      end

      def removed_items
        removed = []
        [:classes, :fields, :boxes, :styles, :layouts].each do |category|
          removed.concat(self.send("removed_#{category}"))
        end
        removed
      end
    end
  end
end
