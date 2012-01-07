# encoding: UTF-8

require 'delegate'

module Spontaneous
  class PagePiece < DelegateClass(Page)
    include Plugins::Render

    attr_accessor :owner
    attr_reader   :style_id

    def initialize(owner, target, style_id)
      super(target)
      @owner, @style_id = owner, style_id
    end

    alias_method :target, :__getobj__
    alias_method :parent, :owner

    # Public: when accessed as inner content, pages return
    # the page at the top of the inner content tree as their
    # #page, rather than themselves
    #
    # Returns: the owning Page object
    def page
      owner.page
    end

    def id
      target.id
    end

    def depth
      owner.content_depth + 1
    end

    def style(format = :html)
      target.class.resolve_style(style_name, format)
    end

    def entry
      self
    end

    def export(user)
      target.shallow_export(user).merge(export_styles).merge({
        :depth => self.depth
      })
    end

    def export_styles
      { :style => style_id.to_s,
        :styles => owner.available_styles(target).map { |s| s.schema_id.to_s } }
    end

    def serialize_db
      [target.id, @style_id]
    end

    def style=(style)
      @style_id = style_to_schema_id(style)
      # because it's not obvious that a change to an entry
      # will affect the fields of the owner piece
      # make sure that the owner is saved using an instance hook
      target.after_save_hook do
        owner.save
      end
      owner.entry_modified!(self)
    end

    def style
      target.resolve_style(style_id)
    end

    def template(format = :html)
      style.template(format)
    end
  end
end
