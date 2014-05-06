# encoding: UTF-8

class Spontaneous::Site
  module Selectors
    extend Spontaneous::Concern

    def home
      model.root
    end

    # roots returns the list of top-level pages
    # Only one of these is publicly visible and this is mapped to the
    # configured site domain.
    #
    # The rest are "hidden" roots.
    def roots(user = nil)
      domain = config.site_domain
      roots  = pages_dataset.where(depth: 0).all
      pub, hidden = roots.partition { |p| p.root? }
      map = {}
      map[domain] = pub.first.id unless pub.empty?
      hidden.each { |p| map[p.path] = p.id }
      { "public" => domain, "roots" => map }
    end

    def pages
      pages_dataset.all
    end

    def pages_dataset
      model::Page.order(:depth)
    end

    ID_SELECTOR   = /\A\d+\z/o
    PATH_SELECTOR = /\A[\/#]/o
    UID_SELECTOR  = /\A\$/o

    def [](selector)
      fetch(selector)
    end

    def fetch(selector)
      case selector
      when Symbol
        by_uid(selector.to_s)
      when Fixnum
        by_id(selector)
      when ID_SELECTOR
        by_id(selector)
      when PATH_SELECTOR
        by_path(selector)
      when UID_SELECTOR
        by_uid(selector[1..-1])
      else
        by_uid(selector)
      end
    end

    def by_id(id)
      model.id(id)
    end

    def by_path(path)
      model.path(path)
    end

    def by_uid(uid)
      model.uid(uid)
    end

    def method_missing(method, *args)
      if (page = fetch(method))
        page
      else
        super
      end
    end
  end
end
