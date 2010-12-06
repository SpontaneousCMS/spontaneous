# encoding: UTF-8

module Spontaneous::Plugins
  module PageSearch
    module ClassMethods
      def root
        Spontaneous::Content.first(:path => Spontaneous::SLASH)
      end

      def uid(uid)
        Spontaneous::Content.first(:uid => uid)
      end

      def path(path)
        page = Spontaneous::Content.first(:path => path)
        page = aliased_path(path) if page.nil?
        page
      end

      def aliased_path(path)
        p = path.split(S::SLASH)
        root = p[0..-2].join(S::SLASH)
        @_ps ||= prepare_aliased_path_query
        @_ps.call(:root => root, :slug => p.last)
      end

      protected

      def prepare_aliased_path_query
        # select c2.*
        # from content as c1, content as c2, content as c3 \
        # where c1.path = '/aliases'
        #   and c2.parent_id = c1.id
        #   and c2.target_id = c3.id
        #   and c3.slug = 'b';
        query = S::Content.select(Sequel::LiteralString.new("c2.*")).from(:content___c1, :content___c2, :content___c3).where(:c1__path => :$root, :c2__parent_id => :c1__id, :c2__target_id => :c3__id, :c3__slug => :$slug)
        query.prepare(:first)
      end
    end

    # module InstanceMethods
    # end
  end
end

