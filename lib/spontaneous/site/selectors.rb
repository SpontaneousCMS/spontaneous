# encoding: UTF-8

class Spontaneous::Site
  module Selectors
    extend Spontaneous::Concern

    module ClassMethods
      def default_content_model
        Spontaneous::Content
      end

      def root(content_model = default_content_model)
        content_model.root
      end

      # roots returns the list of top-level pages
      # Only one of these is publicly visible and this is mapped to the
      # configured site domain.
      #
      # The rest are "hidden" roots.
      def roots(user = nil, content_model = default_content_model)
        domain = config.site_domain
        roots  = pages_dataset(content_model).where(depth: 0).all
        pub, hidden = roots.partition { |p| p.root? }
        map = {}
        map[domain] = pub.first.id unless pub.empty?
        hidden.each { |p| map[p.path] = p.id }
        { "public" => domain, "roots" => map }
      end

      def pages(content_model = default_content_model)
        pages_dataset(content_model).all
      end

      def pages_dataset(content_model = default_content_model)
        content_model::Page.order(:depth)
      end

      ID_SELECTOR   = /\A\d+\z/o
      PATH_SELECTOR = /\A[\/#]/o
      UID_SELECTOR  = /\A\$/o

      def [](selector)
        fetch(selector, default_content_model)
      end

      def fetch(selector, content_model = default_content_model)
        case selector
        when Symbol
          by_uid(selector.to_s, content_model)
        when Fixnum
          by_id(selector, content_model)
        when ID_SELECTOR
          by_id(selector, content_model)
        when PATH_SELECTOR
          by_path(selector, content_model)
        when UID_SELECTOR
          by_uid(selector[1..-1], content_model)
        else
          by_uid(selector, content_model)
        end
      end

      def by_id(id, content_model = default_content_model)
        content_model.id(id)
      end

      def by_path(path, content_model = default_content_model)
        content_model.path(path)
      end

      def by_uid(uid, content_model = default_content_model)
        content_model.uid(uid)
      end

      def method_missing(method, *args)
        if (page = fetch(method))
          page
        else
          super
        end
      end
    end # ClassMethods
  end
end
