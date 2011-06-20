# encoding: UTF-8


module Spontaneous
  module Schema
    class SchemaModification


      def initialize(missing_from_map, missing_from_schema, grouped=false)
        @missing_from_map = missing_from_map
        @missing_from_schema = missing_from_schema
        @grouped = grouped
      end

      def select_missing(select_type)
        @missing_from_schema.select do |reference|
          reference.category == select_type
        end
      end

      def added_classes
        @missing_from_map[:type].uniq
      end

      def removed_classes
        select_missing(:type)
      end

      def added_fields
        @missing_from_map[:field].uniq
      end

      def removed_fields
        select_missing(:field)
      end

      def added_boxes
        @missing_from_map[:box].uniq
      end

      def removed_boxes
        select_missing(:box)
      end

      def added_styles
        @missing_from_map[:style].uniq
      end

      def removed_styles
        select_missing(:style)
      end

      def added_layouts
        @missing_from_map[:layout].uniq
      end

      def removed_layouts
        select_missing(:layout)
      end

      def resolvable?
        if @grouped
          simple?
        else
          all_independent_changes?
        end
      end

      def simple?
        only_removed_items? or only_added_items?
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

      def all_independent_changes?
        !changes_grouped_by_owner.find { |change| !change.resolvable? }
      end

      def changes_grouped_by_owner
        @changes_grouped ||= create_changes_grouped_by_owner
      end

      def change_group_key(category, uid)
        "#{category}:#{uid.to_s}"
      end

      def create_changes_grouped_by_owner
        # gulp
        added = Hash.new { |hash, key| hash[key] =
          Hash.new { | hash, key | hash[key] = [] }
        }
        removed = Hash.new { |hash, key| hash[key] = [] }

        # group changed items by UIDs because in the case of removals
        # the owner might have gone (e.g. in the case of a box with
        # a field that has been removed, the field would show as removed
        # and reference the box as owner but that box is no longer present)
        removed_items.each do |removal|
          removed[change_group_key(removal.category, removal.owner_uid)] << removal
        end

        @missing_from_map.each do |category, additions|
          additions.each do |addition|
            # added classes don't have owners
            uid = addition.schema_owner ? addition.schema_owner.schema_id : nil
            added[change_group_key(category, uid)][category] << addition
          end
        end

        owners = added.keys | removed.keys
        grouped = []

        owners.each do |owner|
          grouped << SchemaModification.new(added[owner], removed[owner], true)
        end
        grouped
      end

      def resolve!
        if @grouped
          resolve_simple
        else
          changes_grouped_by_owner.each { |change| change.resolve! }
        end
      end

      def resolve_simple
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
