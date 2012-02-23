# encoding: UTF-8


module Spontaneous::Render
  module PublishContext
    include Spontaneous::Render::ContextBase
    include Spontaneous::Render::RenderCache

    def root
      _with_render_cache("site.root") do
        super
      end
    end

    def compressed_scripts(scripts)
      _with_render_cache(scripts.join(",")) do
        super(scripts)
      end
    end

    def _pages_at_depth(origin_page, depth)
      _with_render_cache("pages_at_depth.#{origin_page.id}.#{depth}") do
        super
      end
    end

    def publishing?
      true
    end
  end # PublishContext
end # Spontaneous::Render
