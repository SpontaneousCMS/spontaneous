# encoding: UTF-8

require 'delegate'

module Spontaneous
  class PagePiece < DelegateClass(Page)
    extend Plugins
    plugin Plugins::Render

    attr_accessor :container
    attr_reader :style_id

    def initialize(container, target, style_id)
      super(target)
      @container, @style_id = container, style_id
    end

    alias_method :target, :__getobj__

    def id
      target.id
    end

    def depth
      container.content_depth + 1
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
      {
        :style => style_id.to_s,
        :styles => container.available_styles(target).map { |s| s.schema_id.to_s },
      }
    end

    def serialize_db
      [target.id, @style_id]
    end

    def style=(style)
      @style_id = style_to_schema_id(style)
      # because it's not obvious that a change to an entry
      # will affect the fields of the container piece
      # make sure that the container is saved using an instance hook
      target.after_save_hook do
        container.save
      end
      container.entry_modified!(self)
    end

    def style
      target.resolve_style(style_id)
    end

    def template(format = :html)
      style.template(format)
    end
  end
end
