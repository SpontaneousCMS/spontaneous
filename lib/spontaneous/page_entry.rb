
module Spontaneous
  class PageEntry < Entry
    def self.find_target(container, id)
      Content[id]
    end

    def depth
      container.depth + 1
    end
  end
end
