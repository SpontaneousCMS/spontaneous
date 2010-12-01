# encoding: UTF-8


module Spontaneous::Plugins
  module Site
    module Publishing

      module BackgroundPublishing
        def self.publish(revision, pages=nil)
          # launch background publish to call 
          # ImmediatePublishing.publish with the same args
        end
      end

      module ImmediatePublishing
        def self.publish(revision, pages=nil)
          Spontaneous::Content.publish(revision, pages)
          # render step here
          after_publish(revision)
        end

        def self.after_publish(revision)
          Spontaneous::Revision.create(:revision => revision, :published_at => Time.now)
          Spontaneous::Site.send(:set_published_revision, revision)
        end
      end

      module ClassMethods
        def publishing_method
          @publishing_method ||= ImmediatePublishing
        end

        def publishing_method=(method)
          case method
          when :background
            @publishing_method = BackgroundPublishing
          else
            @publishing_method = ImmediatePublishing
          end
        end

        def publish_changes(change_list=nil)
          change_set = Spontaneous::ChangeSet.new(change_list.flatten)
          publish(change_set.page_ids)
        end

        def publish_page(page)
          publish([page])
        end

        def publish_all
          publish
        end

        protected

        def set_published_revision(revision)
          instance = Spontaneous::Site.instance
          instance.published_revision = revision
          instance.revision = revision + 1
          instance.save
        end

        def publish(pages=nil)
          publishing_method.publish(self.revision, pages)
        end

      end # ClassMethods

    end # Publishing
  end # Site
end # Spontaneous::Plugins


