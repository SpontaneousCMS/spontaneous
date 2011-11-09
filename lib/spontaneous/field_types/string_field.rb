# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class StringField < Field
      plugin Spontaneous::Plugins::Field::EditorClass
      def generate_html(value)
        escape_html(value)
      end
    end
    StringField.register
  end
end

