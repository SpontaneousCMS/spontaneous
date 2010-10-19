
module Spontaneous
  class PageEntry < Entry
    def self.find_target(container, id)
      Content[id]
    end

    def depth
      container.depth + 1
    end

    def style
      target.class.inline_styles[style_name]
    end

    def to_hash
      target.to_shallow_hash.merge(styles_to_hash).merge({
        :depth => self.depth
      })
    end
  end
end
