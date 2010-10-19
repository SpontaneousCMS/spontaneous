
module Spontaneous
  class Page < Content

    plugin Plugins::PageStyles
    plugin Plugins::Paths
    plugin Plugins::PageTree
    plugin Plugins::SiteMap

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
    def to_shallow_hash
      hash = super.merge({
        :path => path,
        :slug => slug,
        :uid => uid
      })
      hash.delete(:label)
      hash.delete(:name)
      hash
    end

  end
end
