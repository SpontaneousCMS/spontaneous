# encoding: UTF-8

require 'simultaneous'
require 'sass'

module Spontaneous
  module Publishing
    class Immediate
      include ::Simultaneous::Task

      attr_reader :revision

      def initialize(revision, content_model)
        @revision, @content_model = revision, content_model
        @previous_revision = Spontaneous::Site.published_revision
      end

      def renderer
        @renderer ||= Spontaneous::Output::Template::PublishRenderer.new(true)
      end

      def publish_pages(page_list)
        pages = page_list.flatten.map { |c|
          c.is_a?(@content_model::Page) ? c.reload : @content_model::Page[c]
        }
        all_pages = @content_model::Page.all

        if (all_pages - pages).empty?
          # publish_all is quicker
          publish_all
        else
          pages = Spontaneous::Change.include_dependencies(pages)
          # changes = pages.map { |page| Spontaneous::Change.new(page) }
          publish(pages)

          # TODO: scheduled publishes will
          # changes.each do |change|
          #   change.destroy
          # end
        end

      end

      def publish_all
        # maybe someone will make a change while we're publishing the site
        # (but after we've duplicated the tables)
        # so save the current list of changes
        # TODO: make sure this is robust
        # changes = S::Change.all
        publish(nil)
        # changes.each do |change|
        #   change.destroy
        # end
      end

      def rerender_revision
        logger.info {  "Re-rendering revision #{@revision}"}
        render_revision
      end

      protected

      def page_rendered(page, event = "rendering", format = "html")
        @pages_rendered += 1
        update_progress(event, percent_complete)
        logger.info { "Done: #{event} page #{page.path} (#{format}) #{percent_complete.round(1)}%" }
      end


      def pages
        @pages ||= Spontaneous::Site.pages(@content_model)
      end

      # The number of times the publisher has to run through the site's pages
      # in order to generate the search indexes.
      # Returns either 0 or 1
      def index_stages
        [1, S::Site.indexes.length].min
      end

      def publish(modified_page_list)
        logger.info {  "Publishing revision #{@revision}"}
        at_exit {
          abort_publish_at_exit
        }
        before_publish
        begin
          @content_model.publish(revision, modified_page_list) do
            render_revision
          end
          after_publish
        rescue ::Exception => e
          abort_publish(e)
          raise(e)
        end
      end

      def render_revision
        S::Output.renderer = renderer
        update_progress("rendering", 0)
        @pages_rendered = 0
        @content_model.scope(@revision, true) do
          render_pages
          index_pages unless index_stages == 0
        end
        copy_static_files
        generate_rackup_file
      end

      def render_pages
        # the delay is purely used in interface testing
        delay = Spontaneous::Site.config.publishing_delay
        pages.each do |page|
          page.outputs.each do |output|
            render_page(page, output)
          end
          sleep(delay) if delay
        end
      end

      def render_page(page, output)
        logger.info { "#{page.path}" }
        output.publish_page(renderer, revision)
        page_rendered(page, "rendering", output.format)
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
      # Calculated by (pages * indexes) + (pages * formats)
      # where indexes = Site.indexes.length > 0 ? 1 : 0
      # although not all pages are included by a format
      def total_pages_to_render
        @total_pages ||= \
          begin
            index_steps  = (index_stages * pages.count)
            output_steps = pages.map { |page| page.outputs.length }.inject(0, :+)
            index_steps  + output_steps
        end
      end

      def percent_complete
        ((@pages_rendered || 0).to_f / (total_pages_to_render).to_f) * 100.0
      end

      # Deprecated. It's easier to use the messaging path provided by Simultaneous
      # as it's auto configuring.
      def event_client
        @event_client ||= Spontaneous::Publishing::EventClient.new(ENV["SPOT_SERVER"])
      end

      def update_progress(state, progress='*')
        simultaneous_event('publish_progress', {:state => state, :progress => progress}.to_json)
      end

      def generate_rackup_file
        # use the real path to the app rather than the symlink in order to sandbox the live site
        # not sure that this is a good idea: it would force a publish for every deploy
        # which is only sometimes appropriate/desirable
        # UPDATE: What was I on about there? The true downside to this is that it would force a restart/HUP for
        # every publish. Not sure that the comment above this one is based on truth or some mad momentary fantasy
        path = Pathname.new(Spontaneous.root).realpath.to_s
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
        FileUtils.mkdir_p(public_dest) unless File.exists?(public_dest)
        facets = Spontaneous.instance.facets
        public_dirs = facets.map { |facet| facet.paths.expanded(:public) }.flatten
        facets.each do |facet|
          copy_facet_public_files(facet, public_dest)
        end
      end

      def copy_facet_public_files(facet, public_dest)
        public_dirs = facet.paths.expanded(:public).map { |dir| Pathname.new(dir) }
        public_dirs.each do |public_src|
          if public_src.exist?
            public_src = public_src.realpath
            Dir[public_src.to_s / "**/*"].each do |src|
              src = Pathname.new(src)
              # insert facet namespace in front of path to keep URLs consistent across
              # the back & front servers
              dest = [facet.file_namespace, src.relative_path_from(public_src).to_s].compact
              dest = (public_dest + File.join(dest))
              if src.directory?
                dest.mkpath
              else
                case src.extname
                when ".scss"
                  render_sass_template(src, dest)
                else
                  link_file(src, dest)
                end
              end
            end
          end
        end
      end

      def link_file(src, dest)
        src_dev = File::stat(src).dev
        dst_dev = File::stat(File.dirname(dest)).dev
        if (src_dev == dst_dev)
          FileUtils.ln(src, dest, :force => true)
        else
          FileUtils.cp(src, dest)
        end
      end

      def render_sass_template(template, dest)
        dest_css = [dest.basename('.scss'), "css"].join(".")
        dest = (dest.dirname + dest_css)

        dir = File.dirname(template)
        load_paths = [dir, File.join(dir, "sass")]

        File.open(dest, 'w') do |file|
          begin
            engine = Sass::Engine.for_file(template.to_s, {
              :filename => template.to_s,
              :load_paths => load_paths,
              :cache => false,
              :style => :compressed
            })
            file.write(engine.render)
          rescue Sass::SyntaxError => e
            # it's likely that the error is coming from rendering an include file that isn't designed to
            # be rendered singly (i.e. it depends on another include file)
            # but let's show an error anyway
            logger.warn(e)
          end
        end
      end

      def before_publish
        update_progress("initialising")
        # when working with multiple instances it's possible to rollback the revision number
        # leaving behind old revisions > the current published_revision.
        @content_model.delete_revision(revision)
        Spontaneous::Site.send(:pending_revision=, revision)
      end

      def after_publish
        update_progress("finalising")
        S::Revision.create(:revision => revision, :published_at => Time.now)
        Spontaneous::Site.send(:set_published_revision, revision)
        tmp = Spontaneous.revision_dir(revision) / "tmp"
        FileUtils.mkdir_p(tmp) unless ::File.exists?(tmp)
        symlink_revision(revision)

        begin
          Spontaneous::Site.trigger(:after_publish, revision)
          Spontaneous::Site.send(:pending_revision=, nil)
          update_progress("complete")
        rescue Exception => e
          # if a post publish hook raises an exception then we want to roll everything back
          S::Revision.filter(:revision => revision).delete
          Spontaneous::Site.send(:set_published_revision, @previous_revision)
          symlink_revision(@previous_revision)
          abort_publish(e)
          raise e
        end
      end

      def symlink_revision(rev)
        system("ln -nsf #{Spontaneous.revision_dir(rev)} #{Spontaneous.revision_dir}")
      end

      def abort_publish_at_exit
        abort_publish(nil)
      end

      def abort_publish(exception)
        if r = S::Site.pending_revision
          update_progress("aborting")
          FileUtils.rm_r(Spontaneous.revision_dir(revision)) if File.exists?(Spontaneous.revision_dir(revision))
          Spontaneous::Site.send(:pending_revision=, nil)
          @content_model.delete_revision(revision)
          puts exception.backtrace.join("\n") if exception
          update_progress("error", exception)
        end
      end
    end # Immediate
  end # Publishing
end # Spontaneous
