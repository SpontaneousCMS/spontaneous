# encoding: UTF-8

module Spontaneous::Model::Page
  module PageTree
    extend Spontaneous::Concern

    # InstanceMethods

    def ancestors
      @ancestors ||= ancestor_path.map { |id| content_model[id] }
    end

    def ancestor(at_depth)
      return self if at_depth == depth
      ancestors[at_depth]
    end

    # Returns a list of all the pages at a certain depth in the page tree for any page
    # In the case of pages rooted in a private tree the calculation is done starting from
    # the public root rather than the root of the tree the page belongs to
    def at_depth(depth, opts = {})
      return root_at_depth(depth) if is_public_root? || is_private_root?
      parent_depth = [0, depth - 1].max
      parent = if (parent_depth == 0)
        public_root
      else
        ancestor(parent_depth)
      end

      # in the case of page aliases & private roots it's possible for a template
      # to ask for an ancestor that doesn't exist.
      return [] if parent.nil?

      # This is made more complex because the #children method is unordered
      # whereas the actual page order must come from the boxes
      return parent.children if parent.boxes.empty?

      # Iterate through the list of boxes and pull out of the
      # unordered page list each page that belongs to the current box
      boxes = parent.boxes

      filter_proc = filter_list = nil

      if (filter_list = (opts.delete(:only) || opts.delete(:box) || opts.delete(:boxes)))
        filter_list = Array(filter_list)
        filter_proc = proc { |box| filter_list.include?(box._name) }
      elsif (filter_list = opts.delete(:except))
        filter_list = Array(filter_list)
        filter_proc = proc { |box| !filter_list.include?(box._name) }
      end

      if filter_list && filter_proc
        filter_list = Array(filter_list).map(&:to_sym)
        boxes  = boxes.select(&filter_proc)
      end

      ordered_pages = parent.ordered_pages(boxes)

      filter_proc = filter_list = nil

      if (filter_list = opts.delete(:include))
        filter_proc = proc { |p| filter_list.include?(p.content_class) }
      elsif (filter_list = opts.delete(:exclude))
        filter_proc = proc { |p| !filter_list.include?(p.content_class) }
      end

      if filter_list && filter_proc
        filter_list = Array(filter_list).map { |s| Class === s ? s : s.to_s.constantize }
        ordered_pages = ordered_pages.select(&filter_proc)
      end
      ordered_pages
    end

    def ordered_pages(boxes)
      boxes.flat_map { |box| box.select(&:page?) }
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
