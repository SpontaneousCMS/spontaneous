# encoding: UTF-8

module Spontaneous::Model::Core
  module SchemaHierarchy
    extend Spontaneous::Concern

    module ClassMethods
      def schema_validate(schema)
        if schema_id.nil?
          schema.missing_id!(:type, self)
        else
          # only need to check internal consistency if class already existed
          fields.each do |field|
            if field.owner == self and field.schema_id.nil?
              schema.missing_id!(:field, field)
            end
          end
          # boxes don't have boxes
          if respond_to?(:boxes)
            boxes.each do |box|
              if box.owner == self and box.schema_id.nil?
                schema.missing_id!(:box, box)
              end
            end
          end

          styles.each do |style|
            if style.owner == self and style.schema_id.nil?
              schema.missing_id!(:style, style)
            end
          end
          if respond_to?(:layouts)
            layouts.each do |layout|
              if layout.owner == self and layout.schema_id.nil?
                schema.missing_id!(:layout, layout)
              end
            end
          end
          # Group memberships can get out of sync if a class is modified
          # but their details are transient & not stored in the map so
          # we don't need to raise any errors and can fix things auto-
          # matically.
          if respond_to?(:group_memberships)
            type_memberships = group_memberships || []
            schema_memberships = schema.group_memberships(self)
            if type_memberships != schema_memberships
              schema.remove_group_members(self)
              schema.add_group_member(self, type_memberships)
            end
          end
        end
      end

      # TODO: Delete this?
      def schema_reset!
      end

      def __source_file=(path)
        @__source_file ||= path
      end

      protected(:__source_file=)

      def __source_file
        @__source_file
      end

      def __determine_source_file(subclass, _caller)
        src = File.expand_path(_caller.split(':')[0])
        subclass.__source_file = src
      end

      def inherited(subclass, real_caller = nil)
        __determine_source_file(subclass, real_caller || caller[0])
        super(subclass)
      end

      def schema_class?
        true
      end
    end # ClassMethods
  end # SchemaHierarchy
end
