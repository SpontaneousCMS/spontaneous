# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaHierarchy

    module ClassMethods
      def schema_validate
        if schema_id.nil?
          Spontaneous::Schema.missing_id!(:type, self)
        else
          # only need to check internal consistency if class already existed
          fields.each do |field|
            if field.schema_id.nil?
              Spontaneous::Schema.missing_id!(:field, field)
            end
          end
          # boxes don't have boxes
          if respond_to?(:boxes)
            boxes.each do |box|
              if box.schema_id.nil?
                Spontaneous::Schema.missing_id!(:box, box)
              end
            end
          end

          styles.each do |style|
            if style.schema_id.nil?
              Spontaneous::Schema.missing_id!(:style, style)
            end
          end
          if respond_to?(:layouts)
            layouts.each do |layout|
              if layout.schema_id.nil?
                Spontaneous::Schema.missing_id!(:layout, layout)
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

      def descendents
        subclasses.map{ |x| [x] + x.descendents}.flatten
      end

      def inherited(subclass)
        Spontaneous::Schema.classes << subclass if subclass.schema_class?
        subclasses << subclass
        super
      end

      def schema_class?
        true
      end

    end
  end
end


