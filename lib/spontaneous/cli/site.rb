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
      def dump
        prepare! :dump
        Dump.start
      end

      desc "load", "Uploads a dump of the current site to a remote server"
      def load
        prepare! :load
        Load.start
      end

      desc "publish", "Publishes the site"
      method_option :pages, :type => :array, :desc => "List of pages to publish"
      method_option :logfile, :type => :string, :desc => "Location of logfile"
      def publish
        prepare! :publish
        Spontaneous::Site.background_mode = :immediate
        ::Spontaneous::Logger.setup(:logfile => options.logfile) if options.logfile
        say "Creating revision #{Spontaneous::Site.revision}", :green, true
        if options.pages
          say ">  Publishing pages #{options.pages.inspect}", :green, true
          Spontaneous::Site.publish_pages(options.pages)
        else
          say ">  Publishing all", :green, true
          Spontaneous::Site.publish_all
        end
        # Rescue all errors to feed back to the UI
      rescue ::Exception => e
        send_error_notification(e)
      end

      desc "render", "Re-renders the current content"
      def render
        prepare! :render
        Spontaneous::Site.background_mode = :immediate
        Spontaneous::Site.rerender
      end

      desc "revision", "Shows the site status"
      def revision
        prepare! :revision
        say "Site is at revision #{Spontaneous::Site.revision}", :green
      end

      desc "browse", "Launces a browser pointing to the current development CMS"
      def browse
        prepare :browse
        require 'launchy'
        boot!
        ::Launchy.open("http://localhost:#{Spontaneous::Site.config.port}/@spontaneous")
      end

      private

      def send_error_notification(error)
        simultaneous_event('publish_progress', {:state => "error", :progress => error}.to_json)
      end
    end
  end
end
