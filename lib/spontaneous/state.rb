# encoding: UTF-8


module Spontaneous
  class State <  Sequel::Model(:spontaneous_state)
    class << self
      alias_method :sequel_plugin, :plugin
    end


    @@instance = nil

    class << self

      def instance
        return @@instance if @@instance
        unless instance = self.first
          instance = State.create(:revision => 1, :published_revision => 0)
        end
        instance
      end

      # def with_cache(&block)
      #   yield if @@instance
      #   @@instance = self.instance
      #   yield
      # ensure
      #   @@instance = nil
      # end

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

      # Returns the last date at which a Page was added or removed from the site
      # Used to avoid un-necessary loading of the navigation map during editing
      def modified_at
        instance.modified_at || Time.now
      end

      # Called by Page.after_create and Page.after_destroy in order to update
      # the Site's modification time
      def site_modified!
        instance.update :modified_at => Time.now
      end
    end
  end
end
