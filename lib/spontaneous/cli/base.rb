require 'thor'

module Spontaneous
  module Cli
    class Base < Thor
      include Thor::Actions

      class InvalidGenerator < Error
        attr_reader :name
        def initialize(name)
          @name = name
          super()
        end
      end

      class_option :site, :type => :string, :aliases => ["-s", "--root"], :desc => "Site root dir"
      class_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development, :desc => "Spontaneous Environment"
      class_option :mode, :type => :string,  :aliases => "-m", :default => :back, :desc => "Spontaneous mode ('front' or 'back')"
      class_option :help, :type => :boolean, :desc => "Show help usage"

      desc :start, "Starts Spontaneous"
      method_option :adapter,     :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host,        :type => :string,  :aliases => "-h", :desc => "Bind to HOST address"
      method_option :port,        :type => :numeric, :aliases => "-p", :desc => "Use PORT"

      def start
        pids = []
        trap(:INT) { }
        pids << fork { front }
        pids << fork { back }
        sleep(2) # give servers a chance to start
        pids << fork { console }
        Process.wait
        pids.each { | pid | Process.kill(:TERM, pid) rescue nil }
      end

      desc :server, "Starts Spontaneous"
      alias_method :server, :start


      desc :front, "Starts Spontaneous in front/public mode"
      def front
        start_server(:front)
      end

      desc :back, "Starts Spontaneous in back/CMS mode"
      def back
        start_server(:back)
      end

      desc :publish, "Publishes the site"
      method_option :changes, :type => :array, :desc => "List of changesets to include"
      method_option :logfile, :type => :string, :desc => "Location of logfile"

      def publish
        prepare :publish
        # TODO: set up logging
        require File.expand_path('config/boot.rb')
        Spontaneous::Logger.setup(:logfile => options.logfile) if options.logfile
        logger.info { "publishing revision #{Site.revision} of site #{options.site}" }
        if options.changes
          logger.info "Publishing changes #{options.changes.inspect}"
          Site.publish_changes(options.changes)
        else
          logger.info "Publishing all"
          Site.publish_all
        end
      end

      desc :revision, "Shows the site status"
      def revision
        prepare :revision
        require File.expand_path('config/boot.rb')
        puts "Site is at revision #{Site.revision}"
      end

      desc :console, "Gives you console access to the current site"
      def console
        prepare :console
        ARGV.clear
        puts "=> Loading #{options.environment} console"
        require 'irb'
        require File.expand_path('config/boot.rb')
        IRB.setup(nil)
        irb = IRB::Irb.new
        IRB.conf[:MAIN_CONTEXT] = irb.context
        irb.context.evaluate("require 'irb/completion'", 0)
        irb.context.evaluate("require '#{File.expand_path(File.dirname(__FILE__) + '/console')}'", 0)
        irb.context.evaluate("include Spontaneous", 0)
        trap("SIGINT") do
          irb.signal_handle
        end
        catch(:IRB_EXIT) do
          irb.eval_input
        end
      end


      desc :generate, "Executes the Spontaneous generator with given options."
      def generate(*args)
        require File.expand_path('../../../spontaneous', __FILE__)
        ARGV.shift
        generator_name = ARGV.shift
        generator = nil
        d = Spontaneous::Generators
        case generator_name
        when ''
          raise InvalidGenerator.new(generator_name)
        when 'site'
          generator = d::Site
        when 'page'
          prepare :generator
            require File.expand_path('config/boot.rb')
          generator = d::Page
        when /[a-zA-Z0-9-]+(\.[a-z]+)+/
          # generator called as 'spot generate domain.com'
          ARGV.unshift(generator_name)
          generator = d::Site
        else
          raise InvalidGenerator.new(generator_name)
        end
        generator.start(ARGV) if generator
      rescue InvalidGenerator => e
        say "Unrecognised generator '#{e.name}'. Available options are:\n\n  #{available_generators.join("\n  ")}\n"
      end

      desc "g", "Executes the Spontaneous generator with given options."
      alias :g :generate

      private
      def prepare(task)
        if options.help?
          help(task.to_s)
          raise SystemExit
        end
        ENV["SPOT_ENV"] ||= options.environment.to_s
        ENV["SPOT_MODE"] ||= options.mode.to_s
        ENV["RACK_ENV"] = ENV["SPOT_ENV"] # Also set this for middleware
        chdir(options.site)
        unless File.exist?('config/boot.rb')
          puts "=> Could not find boot file in: #{options.chdir}/config/boot.rb\n=> Are you sure this is a Spontaneous site?"
          raise SystemExit
        end
      end

      def start_server(mode)
        prepare mode.to_sym
        ENV["SPOT_MODE"] = mode.to_s
        require File.expand_path(File.dirname(__FILE__) + "/adapter")
        require File.expand_path('config/boot.rb')
        Spontaneous::Cli::Adapter.start(options)
      end

      def available_generators
        Spontaneous::Generators.available.map do |g|
          g.name.demodulize.underscore
        end
      end

      protected
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

    end # Base
  end # Cli
end # Spontaneous
