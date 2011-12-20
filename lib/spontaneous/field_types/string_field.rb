# encoding: UTF-8

module Spontaneous
  module FieldTypes
    class StringField < Field
      include Spontaneous::Plugins::Field::EditorClass

      def generate_html(value)
        escape_html(value)
      end
    end
    StringField.register
  end
end
