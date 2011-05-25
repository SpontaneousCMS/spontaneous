# encoding: UTF-8

module Spontaneous::Plugins
  module SchemaHierarchy

    module ClassMethods
      def schema_validate
        if schema_id.nil?
          Spontaneous::Schema.missing_id!(self)
        end
        # field_prototypes.each do |field|
        #   Spontaneous::Schema.missing_id!(self, :field, field.name) unless field.schema_id
        # end
      end

      def subclasses
        @subclasses ||= []
      end

      # supertype is like superclass but stops at the last instance of a Content class
      def supertype=(supertype)
        @supertype = supertype
      end

      def supertype
        @supertype
      end

      def descendents
        subclasses.map{ |x| [x] + x.descendents}.flatten
      end

      def inherited(subclass)
        super
        Spontaneous::Schema.classes << subclass
        subclasses << subclass
        subclass.supertype = self
      end
    end
  end
end


