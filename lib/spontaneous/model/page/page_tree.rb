# encoding: UTF-8

module Spontaneous::Model::Page
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
    # In the case of pages rooted in a private tree the calculation is done starting from
    # the public root rather than the root of the tree the page belongs to
    def at_depth(depth, opts = {})
      return root_at_depth(depth) if is_public_root? || is_private_root?
      parent_depth = [0, depth - 1].max
      parent       = ancestor(parent_depth)
      # This is made more complex because the #children method is unordered
      # whereas the actual page order must come from the boxes
      return parent.children if parent.boxes.empty?

      # Iterate through the list of boxes and pull out of the
      # unordered page list each page that belongs to the current box
      boxes = parent.boxes

      filter_proc = filter_list = nil

      if (filter_list = (opts.delete(:only) || opts.delete(:box) || opts.delete(:boxes)))
        filter_proc = proc { |box| filter_list.include?(box._name) }
      elsif (filter_list = opts.delete(:except))
        filter_proc = proc { |box| !filter_list.include?(box._name) }
      end

      if filter_list && filter_proc
        filter_list = Array(filter_list).map(&:to_sym)
        boxes  = boxes.select(&filter_proc)
      end

      ordered_pages = parent.ordered_pages(boxes)

      filter_proc = filter_list = nil

      if (filter_list = opts.delete(:include))
        filter_proc = proc { |p| filter_list.include?(p.class) }
      elsif (filter_list = opts.delete(:exclude))
        filter_proc = proc { |p| !filter_list.include?(p.class) }
      end

      if filter_list && filter_proc
        filter_list = Array(filter_list).map { |s| Class === s ? s : s.to_s.constantize }
        ordered_pages = ordered_pages.select(&filter_proc)
      end
      ordered_pages
    end

    def ordered_pages(boxes)
      unordered_pages = self.children
      ordered_pages   = []
      boxes.each do |box|
        box_id = box.schema_id.to_s
        in_box, unordered_pages = unordered_pages.partition { |p| p.box_sid == box_id }
        ordered_pages.concat in_box.sort { |a, b| a.position <=> b.position }
      end
      ordered_pages
    end

    def root_at_depth(depth)
      root = public_root
      case depth
      when 0
        root
      when 1
        root.children
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

    def generation(reload = false)
      parent ? parent.children(reload) : [root].compact
    end

    def siblings(reload = false)
      generation(reload).reject { |p| p.id == id }
    end

    def >(page)
      page.ancestors.include?(self)
    end

    def >=(page)
      page == self or self.>(page)
    end
  end
end
