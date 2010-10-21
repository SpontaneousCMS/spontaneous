
module Spontaneous
  module Templates
    class << self
      def clear_cache!
        @template_cache = nil
      end

      def template_cache
        @template_cache ||= {}
      end

      def cached(path, &block)
        unless template_cache.key?(path)
          template_cache[path] = yield
        end
        template_cache[path]
      end
    end
  end
end
