# encoding: UTF-8

require "spontaneous/model/page/controllers"
require "spontaneous/model/page/formats"
require "spontaneous/model/page/layouts"
require "spontaneous/model/page/locks"
require "spontaneous/model/page/page_tree"
require "spontaneous/model/page/paths"
require "spontaneous/model/page/site_map"
require "spontaneous/model/page/site_timestamps"
require "spontaneous/model/page/singleton"

module Spontaneous::Model
  module Page
    extend Spontaneous::Concern

    include Spontaneous::Model::Core::Supertype
    include Controllers
    include Formats
    include Layouts
    include PageTree
    include Paths
    include SiteMap
    include SiteTimestamps
    include Locks
    include Singleton
    include Spontaneous::Model::Core::ContentHash::PageMethods

    included do
      many_to_one_content :parent,   :key => :parent_id, :reciprocal => :unordered_children
      one_to_many_content :unordered_children, :key => :parent_id, :reciprocal => :parent
      one_to_many_content :content, :key => :page_id,   :reciprocal => :page
    end

    # field :title, :string, :default => "New Page"

    module ClassMethods
      def page?
        true
      end

      def export(user = nil)
        super(user).merge(title_field: self.title_field.to_s)
      end

      def title_field
        :title
      end
    end

    def page?
      true
    end

    alias_method :is_page?, :page?

    def parent
      # Test for the common case where a page's owner is also its parent
      if (owner_id == parent_id)
        owner
      else
        super
      end
    end

    def children(reload = false)
      @ordered_children = nil if reload
      @ordered_children ||= generate_ordered_children(unordered_children(reload: reload))
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

    def serialize_db
      [target.id, @style_id]
    end

    def inspecttion_values
      { :id => id, :uid => uid, :path => path }.merge(inspection_fields)
    end

    # PagePieces are == to their target but we must enforce the reverse,
    # that Pages are == to a PagePiece that encloses them
    def eql?(obj)
      super || (Spontaneous::PagePiece === obj && obj.target.eql?(self))
    end
  end
end
