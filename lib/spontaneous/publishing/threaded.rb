# encoding: UTF-8

module Spontaneous
  module Publishing
    class Threaded < Immediate

      alias_method :immediate_publish_changes, :publish_changes

      def publish_changes(change_list)
        Thread.new do
          immediate_publish_changes(change_list)
        end
      end

      alias_method :immediate_publish_all, :publish_all

      def publish_all
        Thread.new do
          immediate_publish_all
        end
      end
    end # Forked
  end # Publishing
end # Spontaneous

