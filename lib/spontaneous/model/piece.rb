# encoding: UTF-8

module Spontaneous::Model
  module Piece
    extend Spontaneous::Concern

    include Spontaneous::Model::Core::Supertype

    # Public: for Pieces #parent is the same as the #owner whereas for pages,
    # parent is the next page up in the page hierarchy.
    #
    # Returns: Content node one up in the page hierarchy
    def parent
      owner
    end

    def export(user = nil)
      super(user).merge(export_styles)
    end


    def export_styles
      h = { style: style_sid.to_s }
      if container
        h.merge!({
          styles: container.available_styles(self).map { |s| s.schema_id.to_s }
        })
      else
        h.merge!({
          styles: self.styles.map { |s| s.schema_id.to_s }
        })
      end
    end

    # Ensure that we map #render* to #render_inline* as Pieces have no non-
    # inline version
    def render(format = :html, params = {}, parent_context = nil)
      render_inline(format, params, parent_context)
    end

    def render_using(renderer, format = :html, params = {}, parent_context = nil)
      render_inline_using(renderer, format, params, parent_context)
    end
  end
end
