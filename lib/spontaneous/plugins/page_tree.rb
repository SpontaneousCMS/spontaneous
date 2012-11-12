# encoding: UTF-8

module Spontaneous::Plugins
  module PageTree
    extend Spontaneous::Concern

    # InstanceMethods

    def ancestors
      @ancestors ||= ancestor_path.map { |id| content_model[id] }
    end

    def ancestor(depth)
      ancestors[depth]
    end

    # Returns a list of all the pages at a certain depth in the page tree for any page
    def at_depth(depth)
      return root_at_depth(depth) if is_root?
      parent_depth = [0, depth - 1].max
      parent = ancestor(parent_depth)
      unordered_pages = parent.children
      # This is made more complex because the #children method is unordered
      # whereas the actual page order must come from the boxes
      return unordered_pages if parent.boxes.empty?
      ordered_pages = []
      # Iterate through the list of boxes and pull out of the
      # unordered page list each page that belongs to the current box
      parent.boxes.each do |box|
        box_id = box.schema_id.to_s
        in_box, unordered_pages = unordered_pages.partition { |p| p.box_sid == box_id }
        ordered_pages.concat in_box.sort { |a, b| a.position <=> b.position }
      end
      ordered_pages
    end

    def root_at_depth(depth)
      case depth
      when 0
        self
      when 1
        self.children
      else
        raise ArgumentError.new("Cannot calculate descendents of root beyond a depth of 1")
      end
    end

    def ancestor?(page)
      ancestor_path.include?(page.id)
    end

    def active?(page)
      page.id == self.id or ancestor?(page)
    end

    def generation
      parent ? parent.children : [root]
    end

    def siblings
      generation.reject { |p| p === self }
    end

    def >(page)
      page.ancestors.include?(self)
    end

    def >=(page)
      page == self or self.>(page)
    end
  end
end
