# encoding: UTF-8


module Spontaneous
  class PageEntry < Entry
    def self.find_target(container, id)
      Content[id]
    end

    def depth
      container.content_depth + 1
    end

    def style(format = :html)
      target.class.resolve_style(style_name, format)
    end

    def to_hash
      target.to_shallow_hash.merge(styles_to_hash).merge({
        :depth => self.depth
      })
    end
  end
end
