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
          simple_change?
        else
          all_independent_changes?
        end
      end

      def simple_change?
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

      def create_changes_grouped_by_owner
        # gulp
        added = Hash.new { |hash, key|
          hash[key] = Hash.new { | hash, key | hash[key] = [] }
        }
        removed = Hash.new { |hash, key| hash[key] = [] }

        # group changed items by category + UIDs because in the case of removals
        # the owner might have gone (e.g. in the case of a box with
        # a field that has been removed, the field would show as removed
        # and reference the box as owner but that box is no longer present)
        removed_items.each do |removal|
          removed[change_group_key(removal.category, removal.owner_sid)] << removal
        end

        @missing_from_map.each do |category, additions|
          additions.each do |addition|
            added[change_group_key(category, addition.owner_sid)][category] << addition
          end
        end

        owners = added.keys | removed.keys
        grouped = []

        owners.each do |owner|
          grouped << SchemaModification.new(added[owner], removed[owner], true)
        end
        grouped
      end

      def change_group_key(category, uid)
        [category, uid]
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
            logger.warn("Adding #{obj} to Schema")
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
        @missing_from_map.map { |cat, obj| obj }.flatten
      end

      def removed_items
        @missing_from_schema
      end

      def owners
        if @grouped
          added   = added_items.map   { | obj | obj.schema_owner }
          removed = removed_items.map { | uid | uid.schema_owner }
          owners = (added | removed).uniq
          raise "Invalid grouping of schema modifications" unless owners.length == 1
          [owners.first]
        else
          changes_grouped_by_owner.map { |change| change.owners }
        end
      end

      def error_messages
        if @grouped
          if !simple_change?
            "Unable to resolve changes to #{owners.join(", ")}"
          else
            nil
          end
        else
          changes_grouped_by_owner.map { |change| change.error_messages }.compact
        end
      end

      class Solution < Array
        attr_reader :source
        def initialize(source, destinations)
          super()
          @source, @destinations = source, destinations
          self << Action.new(:delete, source)
          @destinations.each do |dest|
            self << Action.new(:rename, source, dest)
          end
        end

        def description
          "Unable to resolve #{source.category} '#{source.name}' of #{source.owner}"
        end

      end


      class Action
        attr_reader :action, :source, :dest

        def initialize(action, source, dest = nil)
          @action, @source, @dest = action, source, dest
        end

        def description
          case action
          when :delete
            "Delete #{category} '#{source.name}'"
          when :rename
            "Rename #{category} '#{source.name}' to '#{dest.name}'"
          end
        end


        def category
          @source.category
        end

        def to_hash
          hash = [@action.to_s, category, source.name]
          hash << dest.name if dest
          hash
        end
      end

      def actions
        if @grouped
          if simple_change?
            nil
          else
            Solution.new(removed_items.first, added_items)
          end
        else
          change = changes_grouped_by_owner.first { |c| !c.simple_change? }
          change.actions
        end
      end
      def to_hash
        actions.map { |action| action.to_hash }
      end
      def to_json
        to_hash.to_json
      end
    end
  end
end
