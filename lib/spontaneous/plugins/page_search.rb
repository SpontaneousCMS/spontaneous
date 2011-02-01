# encoding: UTF-8

module Spontaneous::Plugins
  module PageSearch
    module ClassMethods
      def root
        first_visible(:path => Spontaneous::SLASH)
      end

      def uid(uid)
        first_visible(:uid => uid)
      end

      def path(path)
        page = first_visible(:path => path)
        page = aliased_path(path) if page.nil?
        page
      end

      def first_visible(params)
        page = Spontaneous::Content.first(params)
        # don't want to return nil if a page matching the params exists but is hidden
        # if we return blank we force searches via other routes (such as aliased pages)
        if page and Spontaneous::Content.visible_only? and page.hidden?
          return false
        end
        page
      end

      def aliased_path(path)
        @_ps ||= Hash.new { |h, k| h[k] = prepare_aliased_path_query(k) }
        p = path.split(S::SLASH)
        root = p[0..-2].join(S::SLASH)
        visible = Spontaneous::Content.visible_only?
        @_ps[visible].call(:root => root, :slug => p.last)
      end

      protected

      def prepare_aliased_path_query(visible_only=false)
        # select c2.*
        # from content as c1, content as c2, content as c3 \
        # where c1.path = '/aliases'
        #   and c2.parent_id = c1.id
        #   and c2.target_id = c3.id
        #   and c3.slug = 'b';
        params = {
          :c1__path => :$root,
          :c2__parent_id => :c1__id,
          :c2__target_id => :c3__id,
          :c3__slug => :$slug
        }
        params.merge!(:c3__visible => true) if visible_only

        query = S::Content.select(Sequel::LiteralString.new("c2.*")).from(:content___c1, :content___c2, :content___c3).where(params)
        query.prepare(:first)
      end
    end

    # module InstanceMethods
    # end
  end
end

