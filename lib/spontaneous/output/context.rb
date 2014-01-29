
module Spontaneous::Output::Context
  autoload :RenderCache, 'spontaneous/output/context/render_cache'
  autoload :Navigation,  'spontaneous/output/context/navigation'

  module ContextCore
    include RenderCache
    include Navigation

    attr_accessor :_renderer, :site


    def page
      __target.page
    end

    def live?
      Spontaneous.production? && publishing?
    end

    def show_errors?
      Spontaneous.development?
    end

    def development?
      Spontaneous.development?
    end

    def root
      site.home
    end

    def site_page(path)
      site[path]
    end

    def asset_environment
      _with_render_cache('asset.environment') do
        Spontaneous::Asset::Environment.new(self)
      end
    end

    def asset_path(path, options = {})
      asset_environment.find(path, options).try(:first)
    end

    def asset_url(path, options = {})
      "url(#{asset_path(path, options)})"
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

    def this
      __target
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

    # template takes an existing first-pass template, converts it to a second pass template
    # and then returns the result for inclusion.
    # This lets you share templates between the publish step and the request step.
    # Useful for things like search results where you want to list the results using the same
    # layout that you used in the static list
    def template(template_path)
      __loader.template(template_path).convert(Spontaneous::Output::Template::RequestSyntax)
    end

    alias_method :defer, :template

    def __format
      __loader.format
    end

    def __decode_params(param)
      return param if param.is_a?(String)
      if param.respond_to?(:render)
        param = __render_content(param) #render(param, param.template)
      end
      param.to_s
    end

    # Has to be routed through the top-level renderer so as to make
    # use of shared caches that are held by it.
    def __render_content(content)
      if content.respond_to?(:render_using)
        content.render_using(_renderer, __format, {}, self)
      else
        content.render(__format, {}, self)
      end
    end
  end

  module PublishContext

    def root
      _with_render_cache("site.root") do
        super
      end
    end

    def site_page(path)
      _with_render_cache("site_page.#{path}") do
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

    def __pages_at_depth(origin_page, depth, opts = {})
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
