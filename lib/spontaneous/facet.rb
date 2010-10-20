
module Spontaneous
  class Facet < Content
    many_to_one :page, :class => Content, :key => :page_id, :reciprocal => :facets
      # def page=(page)
      #   puts "Facet#page= #{page}"
      #   super
      #   slots.each do |slot|
      #     puts "slot[#{slot.class}].page = #{page}"
      #     slot.page = page if slot.respond_to?(:page=)
      #     p slot.page_id
      #   end
      # end
  end
end
