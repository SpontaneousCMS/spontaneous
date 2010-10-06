
module Spontaneous
  module FieldTypes
    class Image < Field
    end
  end
end

Spontaneous::Content.const_set(:Image, Spontaneous::FieldTypes::Image)
