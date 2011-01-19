# encoding: UTF-8


module Spontaneous::Plugins
  module Site
    module Publishing
      module ClassMethods
        def revision_dir(revision=nil)
          return S.revision_root / 'current' if revision.nil?
          S.revision_root / revision.to_s.rjust(5, "0")
        end

        def publishing_method
          @publishing_method ||= default_publishing_method
        end

        def default_publishing_method
          S::Publishing::Immediate
        end

        def publishing_method=(method)
          klass_name = method.to_s.camelize
          begin
            @publishing_method = S::Publishing.const_get(klass_name)
          rescue NameError => e
            @publishing_method = default_publishing_method
          end
        end

        def publish_changes(change_list=nil)
          publishing_method.new(self.revision).publish_changes(change_list)
        end

        def publish_all
          publishing_method.new(self.revision).publish_all
        end

        def publishing_status
          publishing_method.status
        end

        def publishing_status=(status)
          publishing_method.status = status
        end

        protected

        def set_published_revision(revision)
          instance = S::Site.instance
          instance.published_revision = revision
          instance.revision = revision + 1
          instance.save
        end

        def pending_revision=(revision)
          instance = S::Site.instance
          instance.pending_revision = revision
          instance.save
        end
      end # ClassMethods
    end # Publishing
  end # Site
end # Spontaneous::Plugins

