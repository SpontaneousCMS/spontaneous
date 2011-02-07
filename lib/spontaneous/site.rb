# encoding: UTF-8


module Spontaneous
  class Site <  Sequel::Model(:sites)
    class << self
      alias_method :sequel_plugin, :plugin
    end

    extend Plugins

    plugin Plugins::Site::Publishing

    @@instance = nil

    class << self

      def instance
        return @@instance if @@instance
        unless instance = self.first
          instance = Site.create(:revision => 1, :published_revision => 0)
        end
        instance
      end

      def with_cache(&block)
        yield if @@instance
        @@instance = self.instance
        yield
      ensure
        @@instance = nil
      end

      def map(root_id=nil)
        if root_id.nil?
          Page.root.map_entry
        else
          Content[root_id].map_entry
        end
      end

      def root
        Page.root
      end

      def [](path_or_uid)
        case path_or_uid
        when /^\//
          by_path(path_or_uid)
        when /^#/
          by_uid(path_or_uid[1..-1])
        else
          by_uid(path_or_uid)
        end
      end

      def by_path(path)
        Page.path(path)
      end

      def by_uid(uid)
        Page.uid(uid)
      end

      def method_missing(method, *args, &block)
        if p = self[method.to_s]
          p
        else
          super
        end
      end
      def working_revision
        instance.revision
      end

      def revision
        instance.revision
      end

      def published_revision
        if ENV.key?(Spontaneous::SPOT_REVISION_NUMBER)
          ENV[Spontaneous::SPOT_REVISION_NUMBER]
        else
          instance.published_revision
        end
      end

      def pending_revision
        instance.pending_revision
      end

      def config
        Spontaneous.config
      end
    end
  end
end
