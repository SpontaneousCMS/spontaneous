# encoding: UTF-8


module Spontaneous
  class Piece < Content
    set_inheritance_root
    def to_hash
      super.merge(styles_to_hash)
    end

    def styles_to_hash
      {
        :style => style_sid.to_s,
        :styles => container.available_styles(self).map { |s| s.schema_id.to_s },
      }
    end
  end
end
