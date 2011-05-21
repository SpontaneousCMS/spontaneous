# encoding: UTF-8


module Spontaneous
  class Piece < Content
    set_inheritance_root
    def to_hash
      super.merge(styles_to_hash)
    end

    def styles_to_hash
      {
        :style => style_id.to_s,
        :styles => container.available_styles(self).map { |n, s| s.name.to_s },
      }
    end
  end
end
