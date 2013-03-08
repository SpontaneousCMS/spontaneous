
module Spontaneous::Output::Context
  module ContextCore
    attr_accessor :__renderer

    def navigation(depth = 1, &block)
      case depth
      when 0, :root
        root
      when 1, :section
        navigation_at_depth(1, &block)
      else
        navigation_at_depth(depth, &block)
      end
    end

    def navigation_at_depth(depth = 1)
      current_page = __target.page
      __pages_at_depth(current_page, depth).each do |p|
        yield(p, current_page.active?(p))
      end
    end

    def __pages_at_depth(origin_page, depth)
      origin_page.at_depth(depth)
    end

    def page
      __target.page
    end

    def live?
      Spontaneous.production? && publishing?
    end

    def show_errors?
      Spontaneous.development?
    end

    def root
      Spontaneous::Site.root
    end

    def asset_environment
      @asset_environment ||= Spontaneous::Asset::Environment.new(self)
    end

    def site
      Spontaneous::Site.instance
    end

    def publishing?
      false
    end

    def each
      content.each { |c| yield(c) } if block_given?
    end

    def each_with_index
      content.each_with_index { |c, i| yield(c, i) } if block_given?
    end

    def map
      content.map { |c| yield(c) } if block_given?
    end

    def content
      __target.iterable
    end

    def pieces
      content
    end

    def render_content
      __target.map do |c|
        __render_content(c)
      end.reject(&:blank?).join("\n")
    end

    def first
      content.first
    end

    def last
      content.last
    end

    def first?
      __target.owner.pieces.first == self
    end

    def last?
      __target.owner.pieces.last == self
    end

    def __format
      __loader.format
    end

    def __decode_params(param)
      unless param.is_a?(String)
        @_render_method ||= "to_#{__loader.format}".to_sym
        if param.respond_to?(@_render_method)
          param = param.send(@_render_method)
        else
          if param.respond_to?(:render)
            param = __render_content(param) #render(param, param.template)
          end
        end
      end
      param.to_s
    end

    # Has to be routed through the top-level renderer so as to make
    # use of shared caches that are held by it.
    def __render_content(content)
      if content.respond_to?(:render_using)
        content.render_using(__renderer, __format, self)
      else
        content.render(__format, self)
      end
    end
  end

  module RenderCache
    def _render_cache_value(key)
      __renderer.render_cache[key]
    end

    def _render_cache_set_value(key, value)
      __renderer.render_cache[key] = value
    end

    def _render_cache_key?(key)
      __renderer.render_cache.key?(key)
    end

    def _with_render_cache(key, &value_block)
      if _render_cache_key?(key)
        _render_cache_value(key)
      else
        _render_cache_set_value(key, yield)
      end
    end
  end

  module PublishContext
    include RenderCache

    def root
      _with_render_cache("site.root") do
        super
      end
    end

    def scripts(*scripts)
      _with_render_cache(scripts.join(",")) do
        super
      end
    end

    def stylesheets(*stylesheets)
      _with_render_cache(stylesheets.join(",")) do
        super
      end
    end

    def __pages_at_depth(origin_page, depth)
      _with_render_cache("pages_at_depth.#{origin_page.id}.#{depth}") do
        super
      end
    end

    def publishing?
      true
    end
  end

  module PreviewContext
  end

  module RequestContext
  end

end
