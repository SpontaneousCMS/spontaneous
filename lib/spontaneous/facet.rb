# encoding: UTF-8


module Spontaneous
  class Facet < Content
    many_to_one :page, :class => Content, :key => :page_id, :reciprocal => :facets
    set_inheritance_root
  end
end
