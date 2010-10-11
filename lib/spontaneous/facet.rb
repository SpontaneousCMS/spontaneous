
module Spontaneous
  class Facet < Content
    many_to_one :page, :class => Content, :key => :page_id, :reciprocal => :facets
  end
end
