# encoding: UTF-8


module Spontaneous
  module FieldTypes
    class DateField < Field
      plugin Spontaneous::Plugins::Field::EditorClass
    end

    DateField.register
  end
end

