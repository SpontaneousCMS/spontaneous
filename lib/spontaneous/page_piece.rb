# encoding: UTF-8

require 'delegate'

module Spontaneous
  class PagePiece < DelegateClass(Page)
    include Spontaneous::Model::Core::Render
    include Spontaneous::Model::Core::ContentHash::PagePieceMethods

    attr_accessor :owner

    def initialize(owner, target, position = nil)
      super(target)
      @owner, @position = owner, position
    end

    alias_method :target, :__getobj__
    alias_method :parent, :owner

    # Public: when accessed as inner content, pages return
    # the page at the top of the inner content tree as their
    # #page, rather than themselves
    #
    # Returns: the owning Page object
    def page
      owner.try(:page)
    end

    # This is used to unwrap pages from their entries within boxes
    def to_page
      target
    end

    # Used by Spontaneous::Model::Core::=== to look inside PagePiece objects
    # and test against the class of the target, not of the proxy
    def content_class
      target.class
    end

    def id
      target.id
    end

    def depth
      owner.content_depth + 1
    end

    def style
     target.style
    end

    def style=(style)
      target.style=(style)
    end

    def entry
      self
    end

    def export(user = nil)
      target.shallow_export(user).merge(export_styles).merge({
        depth: self.depth
      })
    end

    def export_styles
      { style: target.style_sid.to_s,
        styles: owner.available_styles(target).map { |s| s.schema_id.to_s } }
    end

    def inspect
      %(#<PagePiece target=#{target.inspect}>)
    end

    def renderable
      self
    end

    def template(format = :html, renderer = Spontaneous::Output.default_renderer)
      style.template(format, renderer)
    end

    # Ensure that we map #render* to #render_inline* as this version of a page
    # has no non-inline version
    def render(format = :html, params = {}, parent_context = nil)
      render_inline(format, params, parent_context)
    end

    def render_using(renderer, format = :html, params = {}, parent_context = nil)
      render_inline_using(renderer, format, params, parent_context)
    end
  end
end
