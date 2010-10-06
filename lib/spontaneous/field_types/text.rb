
module Spontaneous
  module FieldTypes
    class Text < Field
    end
  end
end

Spontaneous::Content.const_set(:Text, Spontaneous::FieldTypes::Text)
