# encoding: UTF-8

module Spontaneous::Model::Core
  module PageSearch
    extend Spontaneous::Concern

    module ClassMethods
      def root
        first_visible(:path => Spontaneous::SLASH)
      end

      def uid(uid)
        first_visible(:uid => uid)
      end

      def path(path)
        page = first_visible(:path => path)
        # page = aliased_path(path) if page.nil?
        page
      end

      def first_visible(params)
        page = content_model.first(params)
        # don't want to return nil if a page matching the params exists but is hidden
        # if we return blank we force searches via other routes (such as aliased pages)
        return false if page and mapper.visible_only? and page.hidden?
        page
      end
    end # ClassMethods
  end
end
