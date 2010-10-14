module Spontaneous::Plugins
  module SchemaHierarchy

    module ClassMethods
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
        subclasses << subclass
        subclass.supertype = self
      end
    end
  end
end


