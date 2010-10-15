
module Spontaneous
  class Page < Content

    plugin Plugins::PageStyles
    plugin Plugins::Paths
    plugin Plugins::PageTree

    many_to_one :parent,   :class => Content, :reciprocal => :children
    one_to_many :children, :class => Content, :key => :parent_id, :reciprocal => :parent
    one_to_many :facets,   :class => Content, :key => :page_id, :reciprocal => :page 

    field :title, :string, :default_value => "New Page"

    def page?
      true
    end

    def page
      self
    end
  end
end
