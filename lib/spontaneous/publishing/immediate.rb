# encoding: UTF-8

module Spontaneous
  module Publishing
    class Immediate
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
          S::Render.with_engine(Cutaneous::PublishRenderEngine) do
            pages = S::Page.order(:depth)
            # TODO: read the actual config for the available formats
            [:html].each do |format|
              S::Render.render_pages(revision, pages, format)
            end
          end
        end
        copy_static_files(revision)
        generate_rackup_file(revision)
      end

      def self.generate_rackup_file(revision)
        # use the real path to the app rather than the symlink in order to sandbox the live site
        # not sure that this is a good idea: it would force a publish for every deploy
        # which is only sometimes appropriate/desirable
        path = Pathname.new(Spontaneous.root).realpath.to_s
        # TODO: enable custom rack middleware by changing config/front into a proper rackup file
        template = <<-RACKUP
Dir.chdir('#{path}')
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
        S::Site.send(:pending_revision=, nil)
        system("ln -nsf #{S::Site.revision_dir(revision)} #{S::Site.revision_dir}")
      end

      def self.before_publish(revision)
        S::Site.send(:pending_revision=, revision)
      end

      def self.abort_publish(revision)
        FileUtils.rm_r(S::Site.revision_dir(revision)) if File.exists?(S::Site.revision_dir(revision))
        S::Site.send(:pending_revision=, nil)
        S::Content.delete_revision(revision)
      end
    end # Immediate
  end # Publishing
end # Spontaneous
