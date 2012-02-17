require 'spontaneous/cli'

module Spontaneous
  module Cli
    class Site < ::Spontaneous::Cli::Thor
      Spontaneous = ::Spontaneous
      namespace :site

      default_task :browse

      class DumpTask < ::Thor::Group
        protected

        def db_adapter
          ::Spontaneous::Utils::Database.dumper_for_database(database)
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
          dump_path / "database.mysql.gz"
        end

        def database
          Spontaneous.database
        end

        def dump_path
          dump_root / id
        end

        def dump_root
          Spontaneous.cache_dir('dump')
        end

        def relative_dir(path)
          path = Pathname.new(path)
          path.relative_path_from(Pathname.new(Spontaneous.root)).to_s
        end
      end

      class Dump < DumpTask
        def create_dump_dir
          ::FileUtils.mkdir_p(dump_path)
        end

        def dump_database
          say "Creating media archive at '#{relative_dir(database_dumpfile)}'", :green
          sqldump(database_dumpfile)
        end

        def archive_media
          tmp = relative_dir(Spontaneous.media_dir('tmp'))
          src = relative_dir(Spontaneous.media_dir)
          say "Creating media archive at '#{relative_dir(media_archive)}'", :green
          cmd = %(tar czf #{media_archive} --exclude #{tmp} #{src})
          system(cmd)
        end
      end

      class Load < DumpTask
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

      desc "#{namespace}:dump", "Dumps the current site to an archive on the local machine"
      def dump
        prepare :dump
        boot!
        Dump.start
      end

      desc "#{namespace}:load", "Uploads a dump of the current site to a remote server"
      def load
        prepare :load
        boot!
        Load.start
      end

      desc "#{namespace}:publish", "Publishes the site"
      method_option :changes, :type => :array, :desc => "List of changesets to include"
      method_option :logfile, :type => :string, :desc => "Location of logfile"
      def publish
        prepare :publish
        # TODO: set up logging
        boot!
        ::Site.publishing_method = :immediate
        Spontaneous::Logger.setup(:logfile => options.logfile) if options.logfile
        say "Creating revision #{::Site.revision}", :green, true
        if options.changes
          say ">  Publishing changes #{options.changes.inspect}", :green, true
          ::Site.publish_changes(options.changes)
        else
          say ">  Publishing all", :green, true
          ::Site.publish_all
        end
      end

      desc "#{namespace}:revision", "Shows the site status"
      def revision
        prepare :revision
        boot!
        say "Site is at revision #{::Site.revision}", :green
      end

      desc "#{namespace}:browse", "Launces a browser pointing to the current development CMS"
      def browse
        prepare :browse
        require 'launchy'
        boot!
        ::Launchy::Browser.run("http://localhost:#{::Site.config.port}/@spontaneous")
      end
    end
  end
end
