module Spontaneous::Output::Context
  module RenderCache
    def _render_cache_value(key)
      _renderer.render_cache[key]
    end

    def _render_cache_set_value(key, value)
      _renderer.render_cache[key] = value
    end

    def _render_cache_key?(key)
      _renderer.render_cache.key?(key)
    end

    def _with_render_cache(key, &value_block)
      if _render_cache_key?(key)
        _render_cache_value(key)
      else
        _render_cache_set_value(key, yield)
      end
    end
  end
end