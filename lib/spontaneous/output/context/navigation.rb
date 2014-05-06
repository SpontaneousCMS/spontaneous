module Spontaneous::Output::Context
  module Navigation
    def navigation(opts = {}, &block)
      depth = opts.delete(:depth) || 1
      case depth
      when 0, :root
        root
      when 1, :section
        navigation_at_depth(1, opts, &block)
      else
        navigation_at_depth(depth, opts, &block)
      end
    end

    def navigation_at_depth(depth, opts = {})
      current_page = __target.page
      pages = __pages_at_depth(current_page, depth, opts).map { |p| [p, current_page.active?(p)] }
      if block_given?
        pages.each do |p, active|
          yield(p, active)
        end
      else
        pages
      end
    end

    def __pages_at_depth(origin_page, depth, opts = {})
      origin_page.at_depth(depth, opts)
    end
  end
end