
require 'rdiscount'

module Spontaneous
  module FieldTypes
    class DiscountField < Base
      def process(input)
        RDiscount.new(input, :smart, :filter_html).to_html
      end
    end

    DiscountField.register(:discount, :markdown)
  end
end


