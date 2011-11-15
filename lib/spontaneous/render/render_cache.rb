# encoding: UTF-8


module Spontaneous::Render
  module RenderCache
    def _render_cache_value(key)
      Thread.current[key]
    end

    def _render_cache_set_value(key, value)
      Thread.current[key] = value
    end

    def _render_cache_key?(key)
      Thread.current.key?(key)
    end

    def _with_render_cache(key, &value_block)
      if _render_cache_key?(key)
        self._render_cache_value(key)
      else
        self._render_cache_set_value(key, yield)
      end
    end
  end # RenderCache
end # Spontaneous::Render
