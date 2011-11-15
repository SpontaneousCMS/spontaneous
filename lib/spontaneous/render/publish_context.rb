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
  end # PublishContext
end # Spontaneous::Render
