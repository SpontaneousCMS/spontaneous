# encoding: UTF-8

module Spontaneous::Model::Core
  module PageSearch
    extend Spontaneous::Concern

    module ClassMethods
      # An uncached test for the existance of a site home/root page.
      def has_root?
        content_model.filter(:path => Spontaneous::SLASH).count > 0
      end

      def root
        path(Spontaneous::SLASH)
      end

      def uid(uid)
        first_visible("uid:#{uid}", :uid => uid)
      end

      def path(path)
        first_visible("path:#{path}", :path => path)
      end

      def first_visible(cache_key, params)
        mapper.with_cache(cache_key) {
          page = content_model.first(params)
          # don't want to return nil if a page matching the params exists but is hidden
          # if we return blank we force searches via other routes (such as aliased pages)
          return false if page and mapper.visible_only? and page.hidden?
          page
        }
      end
    end # ClassMethods
  end
end
