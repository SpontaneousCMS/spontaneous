# encoding: UTF-8

module Spontaneous::Plugins::Site
  module Publishing
    extend ActiveSupport::Concern

    module ClassMethods
      def default_publishing_method
        resolve_publishing_method(Spontaneous::Site.config.publishing_method || :immediate)
      end

      def publishing_method
        @publishing_method ||= default_publishing_method
      end

      def publishing_method=(method)
        @publishing_method = resolve_publishing_method(method)
      end

      def resolve_publishing_method(method)
        klass_name = method.to_s.camelize
        begin
          S::Publishing.const_get(klass_name)
        rescue NameError => e
          puts "Unknown method #{method} (#{klass_name})"
          S::Publishing::Immediate
        end
      end

      def publish_changes(change_list=nil)
        publishing_method.new(self.revision).publish_changes(change_list)
      end

      def publish_all
        publishing_method.new(self.revision).publish_all
      end

      def publishing_status
        status = rest = nil
        # if r = S::Site.pending_revision
        status, *rest = publishing_method.status.split(':')
        rest = rest.join(':')
        # end
        Hash[[:status, :progress].zip([status, rest])] rescue ""
      end

      def publishing_status=(status)
        publishing_method.status = status
      end

      def with_published(&block)
        S::Content.with_published(&block)
      end

      protected

      def set_published_revision(revision)
        instance = S::State.instance
        instance.published_revision = revision
        instance.revision = revision + 1
        instance.save
      end

      def pending_revision=(revision)
        instance = S::State.instance
        instance.pending_revision = revision
        instance.save
      end
    end # ClassMethods
  end # Publishing
end # Spontaneous::Plugins::Site
