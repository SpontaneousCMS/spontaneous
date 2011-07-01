# encoding: UTF-8


module Spontaneous
  class Page < Content

    plugin Plugins::Supertype
    plugin Plugins::Layouts
    plugin Plugins::Paths
    plugin Plugins::PageTree
    plugin Plugins::SiteMap
    plugin Plugins::PageSearch
    plugin Plugins::Controllers

    many_to_one :parent,   :class => Content, :reciprocal => :children
    one_to_many :children, :class => Content, :key => :parent_id, :reciprocal => :parent
    one_to_many :content,   :class => Content, :key => :page_id, :reciprocal => :page

    # field :title, :string, :default => "New Page"

    set_inheritance_root

    def self.page?
      true
    end

    def self.to_hash
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

    # TODO: configure outputs for each page
    def formats
      [:html]
    end

    def request_redirect(params = nil, request = nil, session = nil)
      # overwrite and return a Page or a string (containing a path) to cause this page to redirect when accessed
      # if you return a [ location, code ] array then the supplied code will be used in the redirection
      # the code can be either a numeric value (301, 302, ...) or one of :permanent (301) or :temporary (302)
    end

    def request_show(params = nil, request = nil, session = nil)
      # use this to let a call to render this page actually render the content of another
      # the response can be:
      #   a uid: in the form 'uid' or '#uid' to have requests to this page show the content from the page (recommended)
      #   a path: "/path/to/page" (not recommended as paths change!)
      #   a Content instance: either a Page or a Piece
      #   anything that responds to #render(format)
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

    def to_shallow_hash
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
