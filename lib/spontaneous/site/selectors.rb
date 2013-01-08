# encoding: UTF-8

class Spontaneous::Site
  module Selectors
    extend Spontaneous::Concern

    module ClassMethods
      def root(content_model = Spontaneous::Content)
        content_model.root
      end

      def pages(content_model = Spontaneous::Content)
        pages_dataset(content_model).all
      end

      def pages_dataset(content_model = Spontaneous::Content)
        content_model::Page.order(:depth)
      end

      def [](path_or_uid)
        case path_or_uid
        when Fixnum, /\A\d+\z/o
          by_id(path_or_uid)
        when /^\//o
          by_path(path_or_uid)
        when /^#/o
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
