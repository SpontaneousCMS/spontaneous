
module Spontaneous
  class Page < Content

    class << self
      def root
        Page.first(:path => SLASH)
      end
    end

    many_to_one :parent, :class => self, :reciprocal => :children 
    one_to_many :children, :class => self, :key => :parent_id, :reciprocal => :parent

    def after_initialize
      self.slug = default_slug if slug.nil?
      super
    end

    def default_slug
      "page-#{Time.now.strftime('%Y%m%d-%H%M%S')}" 
    end

    def root?
      path == SLASH
    end

    def before_create
      place_in_page_tree
      super
    end

    def place_in_page_tree
      if self.parent_id.nil?
        if Page.root.nil?
          make_root
        end
      else
        update_path
      end
    end

    def update_path
      self.path = calculate_path
    end

    def calculate_path
      if parent.nil?
        root? ? SLASH : '' # bad case, no parent but not root
      else
        File.join(parent.path, slug)
      end
    end

    def make_root
      self.path = "/"
      self[:slug] = ""
    end

    def slug=(s)
      new_slug = s.to_s.to_url
      self[:slug] = new_slug
    end

    def page?
      true
    end

    def page
      self
    end
  end
end
