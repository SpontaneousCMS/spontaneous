# encoding: UTF-8


module Spontaneous
  class Piece < Content
    plugin Plugins::Supertype

    set_inheritance_root

    def export
      super.merge(export_styles)
    end

    def export_styles
      h = {
        :style => style_sid.to_s,
      }
      if container
        h.merge!({
          :styles => container.available_styles(self).map { |s| s.schema_id.to_s }
        })
      else
        h.merge!({
          :styles => self.styles.map { |s| s.schema_id.to_s }
        })
      end
    end
  end
end
