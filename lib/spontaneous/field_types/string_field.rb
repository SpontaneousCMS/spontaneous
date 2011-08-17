# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class StringField < Field
      def process_html(value)
        escape_html(value)
      end
    end
    StringField.register
  end
end

