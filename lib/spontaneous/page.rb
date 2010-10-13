
module Spontaneous
  class Page < Content

    class << self
      def root
        Page.first(:path => SLASH)
      end

      def page_style(name, options={})
        page_styles << Style.new(self, name, options)
      end

      def page_styles
        @page_styles ||= StyleSet.new
      end
    end

    many_to_one :parent, :class => Content, :reciprocal => :children
    one_to_many :children, :class => Content, :key => :parent_id, :reciprocal => :parent
    one_to_many :facets, :class => Content, :key => :page_id, :reciprocal => :page 

    def after_initialize
      super
      self.slug = default_slug if slug.nil?
    end

    def before_create
      place_in_page_tree
      super
    end

    def after_save
      super
      check_for_path_changes
    end

    def style
      self.class.page_styles[self.style_id]
    end

    def style=(page_style)
      self.style_id = page_style.name
    end


    def ancestors
      node, nodes = self, []
      nodes << node = node.parent while node.parent
      nodes
    end

    def generation
      parent ? parent.children : root
    end

    def siblings
      generation.reject { |p| p === self }
    end

    def default_slug
      "page-#{Time.now.strftime('%Y%m%d-%H%M%S')}"
    end

    def root?
      path == SLASH
    end

    def root
      Page.root
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

    def make_root
      self[:path] = "/"
      self[:slug] = ""
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

    def slug=(s)
      if (new_slug = s.to_url) != self.slug
        @__slug_changed = true
        self[:slug] = new_slug
        self.update_path
      end
    end

    def check_for_path_changes
      if @__slug_changed
        @__slug_changed = false
        children.each do |child|
          child.propagate_path_changes
        end
      end
    end

    def propagate_path_changes
      self.update_path
      self.save
      children.each do |child|
        child.propagate_path_changes
      end
    end


    def page?
      true
    end

    def page
      self
    end
  end
end
