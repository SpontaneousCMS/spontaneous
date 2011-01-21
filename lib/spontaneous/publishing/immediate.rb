# encoding: UTF-8

module Spontaneous
  module Publishing
    class Immediate

      def self.status
        @status ||= ""
      end

      def self.status=(status)
        @status = status
      end

      attr_reader :revision

      def initialize(revision)
        @revision = revision
        logger.info {  "Publishing revision #{@revision}"}
      end

      def publish_changes(change_list)
        changes = change_list.flatten.map { |c|
          c.is_a?(S::Change) ? c : S::Change[c]
        }
        change_set = S::ChangeSet.new(changes)

        publish(change_set.page_ids)

        changes.each do |change|
          change.destroy
        end
      end

      def publish_all
        publish(nil)
        S::Change.delete
      end

      # Called from the Format#render method to provide progress reports
      def page_rendered(page)
        @pages_rendered += 1
        set_status("rendering", percent_complete)
        logger.info { "Rendered page #{page.path}" }
      end

      protected

      def pages
        @pages ||= S::Page.order(:depth)
      end

      def formats
        # TODO: read the actual config for the available formats
        [:html]
      end

      def render_stages
        # TODO: when search infrastructure is in place modify this to include the indexing steps
        1
      end

      def publish(pages)
        before_publish
        begin
          S::Content.publish(revision, pages)
          render_revision
          after_publish
        rescue Exception => e
          abort_publish
          raise(e)
        end
      end

      def render_revision
        @pages_rendered = 0
        S::Content.with_identity_map do
          S::Render.with_engine(Cutaneous::PublishRenderEngine) do
            set_status("rendering:0")
            formats.each do |format|
              S::Render.render_pages(revision, pages, format, self)
            end
            # only set this after indexing is complete (if any)
            set_status("rendering:100")
          end
        end
        set_status("copying_files")
        copy_static_files
        generate_rackup_file
      end

      # Used to calculate the progress percentage
      def total_pages_to_render
        @total_pages ||= formats.inject(0) do |total, format|
          total += pages.find_all { |page| page.formats.include?(format) }.count
        end
      end

      def percent_complete
        ((@pages_rendered || 0).to_f / (total_pages_to_render * render_stages).to_f) * 100.0
      end

      def set_status(state, progress='*')
        self.class.status = "#{state}:#{progress}"
      end

      def generate_rackup_file
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

      def copy_static_files
        public_dest = Pathname.new(S::Site.revision_dir(revision) / 'public')
        public_src = Pathname.new(Spontaneous.root / 'public').realpath
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

      def before_publish
        set_status("initialising")
        S::Site.send(:pending_revision=, revision)
      end

      def after_publish
        set_status("finalising")
        S::Revision.create(:revision => revision, :published_at => Time.now)
        S::Site.send(:set_published_revision, revision)
        S::Site.send(:pending_revision=, nil)
        system("ln -nsf #{S::Site.revision_dir(revision)} #{S::Site.revision_dir}")
        set_status("complete")
      end

      def abort_publish
        set_status("aborting")
        FileUtils.rm_r(S::Site.revision_dir(revision)) if File.exists?(S::Site.revision_dir(revision))
        S::Site.send(:pending_revision=, nil)
        S::Content.delete_revision(revision)
        set_status("error")
      end
    end # Immediate
  end # Publishing
end # Spontaneous
