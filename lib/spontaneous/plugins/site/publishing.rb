# encoding: UTF-8


module Spontaneous::Plugins
  module Site
    module Publishing

      module BackgroundPublishing
        def self.publish_changes(revision, change_list)
          # launch background publish to call
          # ImmediatePublishing.publish with the same args
          # catch any exceptions and pass them onto some notification
          # system
        end

        def self.publish_all(revision)
        end
      end

      # TODO: perhaps move this into the Site class itself rather than use this
      # external module (keeping background publishing as an external module)
      module ImmediatePublishing
        def self.publish_changes(revision, change_list)
          changes = change_list.flatten.map { |c|
            c.is_a?(S::Change) ? c : S::Change[c]
          }
          change_set = S::ChangeSet.new(changes)

          publish(revision, change_set.page_ids)

          changes.each do |change|
            change.destroy
          end
        end

        def self.publish_all(revision)
          publish(revision, nil)
          S::Change.delete
        end

        protected

        def self.publish(revision, pages)
          before_publish(revision)
          begin
            S::Content.publish(revision, pages)
            render_revision(revision)
            after_publish(revision)
          rescue Exception => e
            abort_publish(revision)
            raise(e)
          end
        end

        def self.render_revision(revision)
          S::Content.with_identity_map do
            S::Render.with_engine(Cutaneous::PublishRenderEngine[revision]) do
              S::Page.order(:depth).each do |page|
                page.render
              end
            end
          end
          copy_static_files(revision)
          generate_rackup_file(revision)
        end

        def self.generate_rackup_file(revision)
          path = Pathname.new(Spontaneous.root)
          template = <<-RACKUP
Dir.chdir('#{path.realpath}')
require 'config/front'
run Spontaneous::Rack::Front.application.to_app
          RACKUP
          rack_file = S::Site.revision_dir(revision) / 'config.ru'
          File.open(rack_file, 'w') { |f| f.write(template) }
        end

        def self.copy_static_files(revision)
          public_dest = Pathname.new(S::Site.revision_dir(revision) / 'public')
          public_src = Pathname.new(Spontaneous.root / 'public')
          FileUtils.mkdir_p(public_dest) unless File.exists?(public_dest)
          Dir[public_src.to_s / "**/*"].each do |src|
            src = Pathname.new(src)
            dest = (public_dest + src.relative_path_from(public_src))
            if src.directory?
              dest.mkpath
            else
              FileUtils.ln(src, dest, :force => true)
            end
          end
        end

        def self.after_publish(revision)
          S::Revision.create(:revision => revision, :published_at => Time.now)
          S::Site.send(:set_published_revision, revision)
          system("ln -nsf #{S::Site.revision_dir(revision)} #{S::Site.revision_dir}")
        end

        def self.before_publish(revision)
          S::Site.send(:pending_revision=, revision)
        end

        def self.abort_publish(revision)
          S::Site.send(:pending_revision=, nil)
          S::Content.delete_revision(revision)
        end
      end

      module ClassMethods
        def revision_dir(revision=nil)
          return S.revision_root / 'current' if revision.nil?
          S.revision_root / revision.to_s.rjust(5, "0")
        end

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
          publishing_method.publish_changes(self.revision, change_list)
        end

        def publish_all
          publishing_method.publish_all(self.revision)
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


__END__
