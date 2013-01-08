# encoding: UTF-8

class Spontaneous::Site
  module Publishing
    extend Spontaneous::Concern

    module ClassMethods
      def content_model
        ::Content
      end

      def background_mode
        @background_mode ||= (Spontaneous::Site.config.background_mode || :immediate)
      end

      def background_mode=(method)
        @background_mode = method
      end

      def resolve_background_mode(mod)
        klass_name = background_mode.to_s.camelize
        begin
          mod.const_get(klass_name)
        rescue NameError => e
          puts "Unknown method #{method} (#{mod}::#{klass_name})"
          mod::Immediate
        rescue NameError => e
          raise "Illegal background mode #{mod}::Immediate"
        end
      end

      def publishing_method
        resolve_background_mode(Spontaneous::Publishing)
      end

      def publish_pages(page_list=nil)
        publishing_method.new(self.revision, content_model).publish_pages(page_list)
      end

      def publish_all
        publishing_method.new(self.revision, content_model).publish_all
      end

      def rerender
        publishing_method.new(self.published_revision, content_model).rerender_revision
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
        ::Content.scope(published_revision, true, &block)
      end

      def with_editable(&block)
        ::Content.scope(nil, false, &block)
      end

      def with_preview(&block)
        ::Content.scope(nil, true, &block)
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
