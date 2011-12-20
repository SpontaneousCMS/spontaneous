# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Selectors
    extend ActiveSupport::Concern

    module ClassMethods
      def root
        Spontaneous::Page.root
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
        Spontaneous::Page[id]
      end

      def by_path(path)
        Spontaneous::Page.path(path)
      end

      def by_uid(uid)
        Spontaneous::Page.uid(uid)
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
