
module Spontaneous
  module FieldTypes
    class Text < Field
    end
  end
end

Spontaneous::FieldTypes::Text.register(:string, :text)
