# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaHierarchy
    module ClassMethods
      def schema_validate
        if schema_id.nil?
          Spontaneous.schema.missing_id!(:type, self)
        else
          # only need to check internal consistency if class already existed
          fields.each do |field|
            if field.owner == self and field.schema_id.nil?
              Spontaneous.schema.missing_id!(:field, field)
            end
          end
          # boxes don't have boxes
          if respond_to?(:boxes)
            boxes.each do |box|
              puts "???? #{box.owner == self}"
              puts "#### #{self}:#{self.object_id} trying box #{box.name}"
              puts "#### supertype #{supertype}:#{supertype.object_id}" if supertype
              if box.owner == self and box.schema_id.nil?
                p "missing box #{box} #{box.instance_class}"
                Spontaneous.schema.missing_id!(:box, box)
              end
            end
          end

          styles.each do |style|
            if style.owner == self and style.schema_id.nil?
              Spontaneous.schema.missing_id!(:style, style)
            end
          end
          if respond_to?(:layouts)
            layouts.each do |layout|
              if layout.owner == self and layout.schema_id.nil?
                Spontaneous.schema.missing_id!(:layout, layout)
              end
            end
          end
        end
      end

      def schema_reset!
        @subclasses = nil
      end

      def subclasses
        @subclasses ||= []
      end

      def __source_file=(path)
        @__source_file = path
      end

      protected(:__source_file=)

      def __source_file
        @__source_file
      end

      def descendents
        subclasses.map{ |x| [x] + x.descendents}.flatten
      end

      def inherited(subclass, real_caller = nil)
        subclass.__source_file = File.expand_path((real_caller || caller[0]).split(':')[0])
        Spontaneous.schema.add_class(subclass)# if subclass.schema_class?
        subclasses << subclass
        super(subclass)
      end

      def schema_class?
        true
      end
    end
  end
end


