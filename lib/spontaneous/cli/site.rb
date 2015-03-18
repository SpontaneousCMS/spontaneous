require 'spontaneous/cli'
require 'simultaneous'

module Spontaneous
  module Cli
    class Site < ::Thor
      include Spontaneous::Cli::TaskUtils
      include ::Simultaneous::Task
      namespace :site

      default_task :browse

      module DumpTask
        protected

        def db_adapter
          @db_adapter ||= ::Spontaneous::Utils::Database.dumper_for_database(database)
        end

        def sqldump(path)
          db_adapter.dump(path)
        end

        def sqlload(path)
          db_adapter.load(path)
        end

        def id
          @id ||= Time.now.strftime("%Y%m%d%H%M%S")
        end

        def media_archive
          dump_path / "media.tgz"
        end

        def database_dumpfile
          dump_path / "database.#{db_adapter.name}.gz"
        end

        def database
          ::Spontaneous.database
        end

        def dump_path
          dump_root / id
        end

        def dump_root
          ::Spontaneous.cache_dir('dump')
        end

        def relative_dir(path)
          path = Pathname.new(path)
          path.relative_path_from(Pathname.new(::Spontaneous.root)).to_s
        end
      end


      class Dump < ::Thor::Group
        include DumpTask

        def create_dump_dir
          ::FileUtils.mkdir_p(dump_path)
        end

        def dump_database
          say "Creating media archive at '#{relative_dir(database_dumpfile)}'", :green
          sqldump(database_dumpfile)
        end

        def archive_media
          tmp = relative_dir(::Spontaneous.media_dir('tmp'))
          src = relative_dir(::Spontaneous.media_dir)
          say "Creating media archive at '#{relative_dir(media_archive)}'", :green
          cmd = %(tar czf #{media_archive} --exclude #{tmp} #{src})
          system(cmd)
        end
      end

      class Load < ::Thor::Group
        include DumpTask

        def find_latest_dump
          root = Pathname.new(dump_root)
          @id = root.entries.
            reject { |dir| dir.file? or dir.basename.to_s =~ /^\./ }.
            map { |p| p.to_s }.
            sort.
            last
        end

        def import_db_data
          say "Importing database from '#{relative_dir(database_dumpfile)}'", :green
          sqlload(database_dumpfile)
        end

        def extract_media
          say "Extracting media from '#{relative_dir(media_archive)}'", :green
          cmd = %(tar xzf #{media_archive})
          system(cmd)
        end
      end

      desc "dump", "Dumps the current site to an archive on the local machine"
      def dump(*args)
        dump_site_data
      end

      desc "load", "Uploads a dump of the current site to a remote server"
      def load(*args)
        load_site_data
      end

      desc "publish", "Publishes the site"
      method_option :pages, :type => :array, :desc => "List of pages to publish"
      method_option :logfile, :type => :string, :desc => "Location of logfile"
      def publish(*args)
        publish_site
      rescue => e
        $stderr.puts(e.message)
        send_error_notification(e)
      end

      desc "render", "Re-renders the current content"
      def render(*args)
        render_site
      end

      no_commands do
        alias_method :rerender, :render
      end

      desc "revision", "Shows the site status"
      def revision(*args)
        show_site_revision
      end

      desc "browse", "Launches a browser pointing to the current development CMS"
      def browse(*args)
        browse_site
      end

      private

      def dump_site_data
        prepare! :dump
        Dump.start
      end


      def load_site_data
        prepare! :load
        Load.start
      end

      def publish_site
        site = prepare! :publish
        site.background_mode = :immediate
        ::Spontaneous::Logger.setup(:logfile => options.logfile) if options.logfile
        say "Creating revision #{site.working_revision}", :green, true
        if options.pages
          say ">  Publishing pages #{options.pages.inspect}", :green, true
          site.publish_pages(options.pages)
        else
          say ">  Publishing all", :green, true
          site.publish_all
        end
        # Rescue all errors to feed back to the UI
      end

      def render_site
        site = prepare! :render
        site.background_mode = :immediate
        site.rerender
      end

      def show_site_revision
        site = prepare! :revision
        say "Site is at revision #{site.working_revision}", :green
      end

      def browse_site
        site = prepare :browse
        require 'launchy'
        boot!
        ::Launchy.open("http://localhost:#{site.config.port}/@spontaneous")
      end

      def send_error_notification(error)
        simultaneous_event('publish_progress', {:state => "error", :progress => error}.to_json)
      end
    end
  end
end
