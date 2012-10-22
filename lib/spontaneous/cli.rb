require 'thor'
require 'thor/group'

module Spontaneous
  module Cli
    module TaskUtils
      # include Thor::Actions

      def self.included(base)
        base.class_eval do
          def self.banner(task, namespace = true, subcommand = false)
            "#{basename} #{task.formatted_usage(self, true, subcommand)}"
          end
        end
        base.class_option :site, :type => :string, :aliases => ["-s", "--root"], :default => ".", :desc => "Site root dir"
        base.class_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development, :desc => "Spontaneous Environment"
        base.class_option :mode, :type => :string,  :aliases => "-m", :default => :back, :desc => "Spontaneous mode ('front' or 'back')"
        base.class_option :help, :type => :boolean, :desc => "Show help usage"
      end


      protected

      def fix_schema(error)
        modification = error.modification
        actions = modification.actions
        say(actions.description, :red)
        say("Please choose one of the solutions below", :yellow)
        actions.each_with_index do |a, i|
          say("  #{i+1}: #{a.description}")
        end
        choice = ( ask "Choose action : ").to_i rescue nil
        if choice and choice <= actions.length and choice > 0
          action = actions[choice - 1]
          begin
            Spontaneous::Schema.apply(action)
          rescue Spontaneous::SchemaModificationError => error
            fix_schema(error)
          end
        else
          say("Invalid choice '#{choice.inspect}'\n", :red)
          fix_schema(error)
        end
      end

      def prepare(task, mode = "console")
        if options.help?
          help(task.to_s)
          raise SystemExit
        end
        ENV["SPOT_ENV"] ||= options.environment.to_s ||
        ENV["RACK_ENV"] = ENV["SPOT_ENV"] # Also set this for middleware
        ENV["SPOT_MODE"] = mode.to_s
        chdir(options.site)
        unless File.exist?('config/boot.rb')
          puts "=> Could not find boot file in: #{options.chdir}/config/boot.rb\n=> Are you sure this is a Spontaneous site?"
          raise SystemExit
        end
      end

      def prepare!(task, mode = "console")
        prepare(task, mode)
        boot!
      end

      def boot!
        begin
          require File.expand_path('config/boot.rb')
        rescue Spontaneous::SchemaModificationError => error
          fix_schema(error)
        end
      end

      def chdir(dir)
        return unless dir
        begin
          Dir.chdir(dir.to_s)
        rescue Errno::ENOENT
          puts "=> Specified site '#{dir}' does not appear to exist"
        rescue Errno::EACCES
          puts "=> Specified site '#{dir}' cannot be accessed by the current user"
        end
      end
    end

    autoload :Console,  "spontaneous/cli/console"
    autoload :Site,     "spontaneous/cli/site"
    autoload :Init,     "spontaneous/cli/init"
    autoload :User,     "spontaneous/cli/user"
    autoload :Generate, "spontaneous/cli/generate"
    autoload :Server,   "spontaneous/cli/server"
    autoload :Media,    "spontaneous/cli/media"
    autoload :Sync,     "spontaneous/cli/sync"
    autoload :Migrate,  "spontaneous/cli/migrate"
    autoload :Assets,   "spontaneous/cli/assets"

    class Root < ::Thor
      register Spontaneous::Cli::Console,  "console",  "console",           "Gives you console access to the current site"
      register Spontaneous::Cli::User,     "user",     "user [ACTION]",     "Administer site users"
      register Spontaneous::Cli::Generate, "generate", "generate [OBJECT]", "Generates things"
      register Spontaneous::Cli::Site,     "site",     "site [ACTION]",     "Run site-wide actions"
      register Spontaneous::Cli::Init,     "init",     "init",              "Creates databases and initialises a new Spontaneous site"
      register Spontaneous::Cli::Server,   "server",   "server [ACTION]",   "Launch development server(s)"
      register Spontaneous::Cli::Media,    "media",    "media [ACTION]",    "Manage site media"
      register Spontaneous::Cli::Sync,     "sync",     "sync [DIRECTION]",  "Sync database and media to and from the production server"
      register Spontaneous::Cli::Migrate,  "migrate",  "migrate",           "Runs Spontaneous migrations"
      register Spontaneous::Cli::Assets,   "assets",   "assets [ACTION]",   "Manage Spontaneous assets"

      desc :browse, "Launces a browser pointing to the current development CMS"
      def browse
        prepare! :browse
        require 'launchy'
        ::Launchy.open("http://localhost:#{::Spontaneous::Site.config.port}/@spontaneous")
      end

      map %w(--version -v) => :version

      desc :version, "Show the version of Spontaneous in use"
      def version
        require "spontaneous/version"
        say "Spontaneous #{Spontaneous::VERSION}"
      end
    end
  end
end
