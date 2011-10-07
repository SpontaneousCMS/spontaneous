# encoding: UTF-8

require 'simultaneous'

module Spontaneous
  module Publishing
    class Immediate

      # def self.status
      #   @status ||= ""
      # end

      # def self.status=(status)
      #   @status = status
      # end

      include ::Simultaneous::Task

      attr_reader :revision

      def initialize(revision)
        @revision = revision
        logger.info {  "Publishing revision #{@revision}"}
      end

      def publish_changes(change_list)
        changes = change_list.flatten.map { |c|
          c.is_a?(S::Change) ? c : S::Change[c]
        }
        all_changes = S::Change.all
        if changes == all_changes
          # publish_all is quicker
          publish_all
        else
          change_set = Spontaneous::Collections::ChangeSet.new(changes)
          publish(change_set.page_ids)

          changes.each do |change|
            change.destroy
          end
        end

      end

      def publish_all
        # maybe someone will make a change while we're publishing the site
        # (but after we've duplicated the tables)
        # so save the current list of changes
        # TODO: make sure this is robust
        changes = S::Change.all
        publish(nil)
        changes.each do |change|
          change.destroy
        end
      end

      # Called from the Format#render method to provide progress reports
      def page_rendered(page, event = "rendering")
        @pages_rendered += 1
        update_progress(event, percent_complete)
        logger.info { "Done: #{event} page #{page.path} #{percent_complete.round(1)}%" }
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

      def publish(modified_page_list)
        at_exit {
          abort_publish_at_exit
        }
        before_publish
        begin
          S::Content.publish(revision, modified_page_list) do
            render_revision
          end
          after_publish
        rescue Exception => e
          abort_publish(e)
          raise(e)
        end
      end

      def render_revision
        update_progress("rendering", 0)
        @pages_rendered = 0
        S::Content.with_identity_map do
          S::Render.with_publishing_renderer do
            render_pages
            index_pages
          end
        end
        copy_static_files
        generate_rackup_file
      end

      def render_pages
        formats.each do |format|
          S::Render.render_pages(revision, pages, format, self)
        end
      end

      def index_pages
        S::Site.indexer(revision) do |indexer|
          pages.each { |page|
            indexer << page
            page_rendered(page, 'indexing')
          }
        end
      end

      # Used to calculate the progress percentage
      # Calculated by (formats + indexes) * pages
      # where indexes = Site.indexes.length > 0 ? 1 : 0
      # although not all pages are included by a format
      def total_pages_to_render
        @total_pages ||= formats.inject([1, S::Site.indexes.length].min * pages.count) do |total, format|
          total += pages.find_all { |page| page.formats.include?(format) }.count
        end
      end

      def percent_complete
        ((@pages_rendered || 0).to_f / (total_pages_to_render * render_stages).to_f) * 100.0
      end

      def update_progress(state, progress='*')
        simultaneous_event('publish_progress', {:state => state, :progress => progress}.to_json)
      end

      def generate_rackup_file
        # use the real path to the app rather than the symlink in order to sandbox the live site
        # not sure that this is a good idea: it would force a publish for every deploy
        # which is only sometimes appropriate/desirable
        path = Pathname.new(Spontaneous.root).realpath.to_s
        # TODO: enable custom rack middleware by changing config/front into a proper rackup file
        rackup = 'config/front.ru'
        template = (<<-RACKUP).gsub(/^ +/, '')
          # This is an automatically generated file *DO NOT EDIT*
          # To configure your Rack application make your changes in
          # '#{path}/#{rackup}'

          # Set the revision to display
          ENV["#{Spontaneous::SPOT_REVISION_NUMBER}"] = '#{revision}'
          ENV["#{Spontaneous::SPOT_ROOT}"] = '#{path}'

          # Change to the absolute path of our application and load the Rack config
          root = '#{path}'
          Dir.chdir(root)
          eval(::File.read('#{rackup}'), binding, ::File.join(root, '#{rackup}'), __LINE__)

        RACKUP
        rack_file = Spontaneous.revision_dir(revision) / 'config.ru'
        File.open(rack_file, 'w') { |f| f.write(template) }
      end

      def copy_static_files
        update_progress("copying_files")
        public_dest = Pathname.new(Spontaneous.revision_dir(revision) / 'public')
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
        update_progress("initialising")
        S::Site.send(:pending_revision=, revision)
      end

      def after_publish
        update_progress("finalising")
        S::Revision.create(:revision => revision, :published_at => Time.now)
        S::Site.send(:set_published_revision, revision)
        S::Site.send(:pending_revision=, nil)
        tmp = Spontaneous.revision_dir(revision) / "tmp"
        FileUtils.mkdir_p(tmp) unless ::File.exists?(tmp)
        system("ln -nsf #{Spontaneous.revision_dir(revision)} #{Spontaneous.revision_dir}")
        update_progress("complete")
      end

      def abort_publish_at_exit
        abort_publish(nil)
      end

      def abort_publish(exception)
        if r = S::Site.pending_revision
          update_progress("aborting")
          FileUtils.rm_r(Spontaneous.revision_dir(revision)) if File.exists?(Spontaneous.revision_dir(revision))
          S::Site.send(:pending_revision=, nil)
          S::Content.delete_revision(revision)
          puts exception.backtrace.join("\n")
          update_progress("error", exception)
        end
      end
    end # Immediate
  end # Publishing
end # Spontaneous
