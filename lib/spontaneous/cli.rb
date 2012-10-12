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

      def prepare(task, mode = nil)
        if options.help?
          help(task.to_s)
          raise SystemExit
        end
        ENV["SPOT_ENV"] ||= options.environment.to_s
        ENV["RACK_ENV"] = ENV["SPOT_ENV"] # Also set this for middleware
        ENV["SPOT_MODE"] = mode.to_s unless mode.nil?
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

    class Runner < ::Thor
      namespace "default"

      remove_task :help

      map %w(-T) => :list, %w(--version -v) => :version

      desc "version", "Show Spontaneous version"
      def version
        require 'spontaneous/version'
        say "Spontaneous #{Spontaneous::VERSION}"
      end

      desc "list [SEARCH]", "List the available tasks (--substring means .*SEARCH)"
      method_options :substring => :boolean, :group => :string, :all => :boolean, :debug => :boolean
      def list(search="")
        initialize_thorfiles

        search = ".*#{search}" if options["substring"]
        search = /^#{search}.*/i
        group  = options[:group] || "standard"

        klasses = Thor::Base.subclasses.select do |k|
          (options[:all] || k.group == group) && k.namespace =~ search
        end

        display_klasses(false, false, klasses)
      end

      # Override Thor#help so it can give information about any class and any method.
      #
      desc "help [TASK]", "Describe available tasks or one specific task"
      def help(task = nil, subcommand = false)
        task ? self.class.task_help(shell, task) : self.class.help(shell, subcommand)
      end


      # Override Thor#help so it can give information about any class and any method.
      #
      def help(meth = nil)
        if meth && !self.respond_to?(meth)
          initialize_thorfiles(meth)
          klass, task = Thor::Util.find_class_and_task_by_namespace(meth)
          klass.start(["-h", task].compact, :shell => self.shell)
        else
          list
        end
      end

      # If a task is not found on Thor::Runner, method missing is invoked and
      # Thor::Runner is then responsable for finding the task in all classes.
      #
      def method_missing(meth, *args)
        meth = meth.to_s
        initialize_thorfiles(meth)
        klass, task = Thor::Util.find_class_and_task_by_namespace(meth)
        args.unshift(task) if task
        klass.start(args, :shell => self.shell)
      end

      private

      # Display information about the given klasses. If with_module is given,
      # it shows a table with information extracted from the yaml file.
      #
      def display_klasses(with_modules=false, show_internal=false, klasses=Thor::Base.subclasses)
        klasses -= [Thor, Thor::Runner, Thor::Group] unless show_internal

        raise Error, "No tasks available" if klasses.empty?
        show_modules if with_modules && !thor_yaml.empty?

        list = Hash.new { |h,k| h[k] = [] }
        groups = klasses.select { |k| k.ancestors.include?(Thor::Group) }

        # Get classes which inherit from Thor
        (klasses - groups).each { |k| list[k.namespace.split(":").first] += k.printable_tasks(false) }

        list.delete("thor")

        # Order namespaces with default coming first
        list = list.sort{ |a,b| a[0].sub(/^default/, '') <=> b[0].sub(/^default/, '') }
        list.each { |n, tasks| display_tasks(n, tasks) unless tasks.empty? }
      end

      def display_tasks(namespace, list) #:nodoc:
        list.sort!{ |a,b| a[0] <=> b[0] }

        say shell.set_color(namespace, :blue, true)
        say "-" * namespace.size

        print_table(list, :truncate => true)
        say
      end

      def initialize_thorfiles(relevant_to=nil, skip_lookup=false)
        thorfiles(relevant_to, skip_lookup).each do |f|
          Thor::Util.load_thorfile(f, nil, options[:debug]) unless Thor::Base.subclass_files.keys.include?(File.expand_path(f))
        end
      end

      def thorfiles(*args)
        task_dir = File.expand_path('../cli', __FILE__)
        Dir["#{task_dir}/*.rb"]
      end
    end

    autoload :Adapter,  "spontaneous/cli/adapter"
    autoload :Base,     "spontaneous/cli/base"
    autoload :Site,     "spontaneous/cli/site"
    autoload :User,     "spontaneous/cli/user"
  end
end

