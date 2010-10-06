
module Spontaneous
  module FieldTypes
    class Date < Field
    end
  end
end

Spontaneous::Content.const_set(:Date, Spontaneous::FieldTypes::Date)
