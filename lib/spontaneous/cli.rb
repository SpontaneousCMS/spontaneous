require 'thor'
require 'thor/runner'

module Spontaneous
  module Cli
    class Thor < ::Thor

      class_option :site, :type => :string, :aliases => ["-s", "--root"], :desc => "Site root dir"
      class_option :environment, :type => :string,  :aliases => "-e", :required => true, :default => :development, :desc => "Spontaneous Environment"
      class_option :mode, :type => :string,  :aliases => "-m", :default => :back, :desc => "Spontaneous mode ('front' or 'back')"
      class_option :help, :type => :boolean, :desc => "Show help usage"

      protected

      def boot!
        begin
          require File.expand_path('config/boot.rb')
        rescue Spontaneous::SchemaModificationError => error
          fix_schema(error)
        end
      end

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

      def prepare(task)
        if options.help?
          help(task.to_s)
          raise SystemExit
        end
        ENV["SPOT_ENV"] ||= options.environment.to_s
        ENV["RACK_ENV"] = ENV["SPOT_ENV"] # Also set this for middleware
        ENV["SPOT_MODE"] ||= options.mode.to_s
        chdir(options.site)
        unless File.exist?('config/boot.rb')
          puts "=> Could not find boot file in: #{options.chdir}/config/boot.rb\n=> Are you sure this is a Spontaneous site?"
          raise SystemExit
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

    class Runner < ::Thor::Runner
      remove_task :install#, :undefine => true

      private

      def thorfiles(*args)
        task_dir = File.expand_path('../cli', __FILE__)
        Dir["#{task_dir}/*.rb"]
      end
    end
  end
end

