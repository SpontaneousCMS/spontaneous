# encoding: UTF-8

class Spontaneous::Site
  module Selectors
    extend Spontaneous::Concern

    module ClassMethods
      def root(content_model = Spontaneous::Content)
        content_model.root
      end

      # roots returns the list of top-level pages
      # Only one of these is publicly visible and this is mapped to the
      # configured site domain.
      #
      # The rest are "hidden" roots.
      def roots(user = nil, content_model = Spontaneous::Content)
        domain = config.site_domain
        roots  = pages_dataset(content_model).where(depth: 0).all
        pub, hidden   = roots.partition { |p| p.root? }
        map = { domain => pub.first.id }
        hidden.each { |p| map[p.path] = p.id }
        { "public" => domain, "roots" => map }
      end

      def pages(content_model = Spontaneous::Content)
        pages_dataset(content_model).all
      end

      def pages_dataset(content_model = Spontaneous::Content)
        content_model::Page.order(:depth)
      end

      ID_PATH   = /\A\d+\z/o
      PATH_PATH = /^[\/#]/o
      UID_PATH  = /^\$/o

      def [](path_or_uid)
        case path_or_uid
        when Fixnum, ID_PATH
          by_id(path_or_uid)
        when PATH_PATH
          by_path(path_or_uid)
        when UID_PATH
          by_uid(path_or_uid[1..-1])
        else
          by_uid(path_or_uid)
        end
      end

      def by_id(id)
        Spontaneous::Content[id]
      end

      def by_path(path)
        Spontaneous::Content.path(path)
      end

      def by_uid(uid)
        Spontaneous::Content.uid(uid)
      end

      def method_missing(method, *args)
        if page = self[method.to_s]
          page
        else
          super
        end
      end
    end # ClassMethods
  end
end
