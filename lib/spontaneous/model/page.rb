# encoding: UTF-8

module Spontaneous::Model
  module Page
    extend Spontaneous::Concern

    include Spontaneous::Plugins::Supertype
    include Spontaneous::Plugins::Page::Formats
    include Spontaneous::Plugins::Layouts
    include Spontaneous::Plugins::Paths
    include Spontaneous::Plugins::PageTree
    include Spontaneous::Plugins::SiteMap
    include Spontaneous::Plugins::Controllers
    include Spontaneous::Plugins::Page::Request
    include Spontaneous::Plugins::Page::SiteTimestamps

    included do
      many_to_one :parent,   :key => :parent_id, :class => self, :reciprocal => :unordered_children
      one_to_many :unordered_children, :class => self, :key => :parent_id, :reciprocal => :parent
      one_to_many :content,  :class => self, :key => :page_id,   :reciprocal => :page
    end

    # field :title, :string, :default => "New Page"

    module ClassMethods
      def page?
        true
      end

      def export(user = nil)
        super(user).merge(:title_field => self.title_field.to_s)
      end

      def title_field
        :title
      end
    end

    def page?
      true
    end

    alias_method :is_page?, :page?

    def children
      @ordered_children ||= generate_ordered_children(unordered_children)
    end

    def generate_ordered_children(unordered_children)
      return unordered_children if self.boxes.empty?
      ordered_pages = unordered_children.sort { |a, b| a.page_order_string <=> b.page_order_string }
      ordered_pages.freeze
    end

    def page_order_string
      @page_order_string ||= (content_ancestors[1..-1].push(self)).map { |a| a.position.to_s.rjust(5, "0") }.join('.')
    end

    def content_ancestors
      obj = self
      ancestors = []
      begin
        obj = obj.container
        ancestors.unshift obj
      end until obj.nil? or obj.is_page?

      ancestors
    end

    def reload
      @ordered_children = @page_order_string = nil
      super
    end

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
      owner.all_contents.find { |e| e.id == self.id }
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

    def shallow_export(user)
      hash = super(user).merge({
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
