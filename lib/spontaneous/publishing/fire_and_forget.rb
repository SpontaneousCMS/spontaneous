# encoding: UTF-8

module Spontaneous
  module Publishing
    class FireAndForget
      def self.publish_changes(revision, change_list)
        # launch background publish to call
        # ImmediatePublishing.publish with the same args
        # catch any exceptions and pass them onto some notification
        # system
      end

      def self.publish_all(revision)
      end
    end # FireAndForget
  end # Publishing
end # Spontaneous

