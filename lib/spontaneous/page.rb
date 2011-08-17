# encoding: UTF-8


module Spontaneous
  class Page < Content

    plugin Plugins::Supertype
    plugin Plugins::Page::Formats
    plugin Plugins::Layouts
    plugin Plugins::Paths
    plugin Plugins::PageTree
    plugin Plugins::SiteMap
    plugin Plugins::PageSearch
    plugin Plugins::Controllers
    plugin Plugins::Page::Request

    many_to_one :parent,   :class => Content, :reciprocal => :children
    one_to_many :children, :class => Content, :key => :parent_id, :reciprocal => :parent
    one_to_many :content,   :class => Content, :key => :page_id, :reciprocal => :page

    # field :title, :string, :default => "New Page"

    set_inheritance_root

    def self.page?
      true
    end

    def self.export
      super.merge(:title_field => self.title_field.to_s)
    end

    def self.title_field
      :title
    end

    def page?
      true
    end

    alias_method :is_page?, :page?

    def before_save
      if parent
        self.depth = parent.depth+1
      end
      super
    end

    def page
      self
    end

    def entry
      @entry ||= resolve_entry
    end

    def resolve_entry
      container.all_pieces.find { |e| e.id == self.id }
    end

    def page=(page)
    end

    def content_depth
      0
    end

    def page_title
      if field = self.fields[title_field]
        field.value
      end
    end

    def title_field
      self.class.title_field
    end

    def shallow_export
      hash = super.merge({
        :path => path,
        :title => page_title,
        :slug => slug,
        :uid => uid
      })
      hash.delete(:label)
      hash.delete(:name)
      hash
    end

  end
end
