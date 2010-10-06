
module Spontaneous
  module FieldTypes
    class Image < Field
    end
  end
end

Spontaneous.const_set(:Image, Spontaneous::FieldTypes::Image)
