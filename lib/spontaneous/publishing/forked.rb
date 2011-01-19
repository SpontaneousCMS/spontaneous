# encoding: UTF-8

module Spontaneous
  module Publishing
    class Forked < Immediate
      def self.publish_changes(revision, change_list)
        fork do
          super
        end
      end

      def self.publish_all(revision)
        fork do
          super
        end
      end
    end # Forked
  end # Publishing
end # Spontaneous

