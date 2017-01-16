# encoding: UTF-8

# require 'spontaneous'
require 'simultaneous'
require 'foreman/engine/cli'

module Spontaneous
  module Cli
    class Server < ::Thor
      include Spontaneous::Cli::TaskUtils

      namespace    :server
      default_task :start

      class_option :no_browser, type: :boolean, default: false, aliases: "-b", desc: "Don't launch browser"

      desc "start", "Starts Spontaneous in development mode"
      def start
        launch %w(back front tasks)
      end

      desc "front", "Starts Spontaneous in front/public mode"
      # method_option :adapter, type: :string,  aliases: "-a", desc: "Rack Handler (default: autodetect)"
      method_option :host, type: :string,  aliases: "-h", desc: "Bind to HOST address"
      method_option :port, type: :numeric, aliases: "-p", desc: "Use PORT"
      def front(*args)
        start_server(:front)
      end

      desc "back", "Starts Spontaneous in back/CMS mode"
      # method_option :adapter, type: :string,  aliases: "-a", desc: "Rack Handler (default: autodetect)"
      method_option :host, type: :string,  aliases: "-h", desc: "Bind to HOST address"
      method_option :port, type: :numeric, aliases: "-p", desc: "Use PORT"
      def back(*args)
        start_server(:back)
      end

      desc "simultaneous", "Launches the Simultaneous server"
      method_option :connection, type: :string, aliases: "-c", desc: "Use CONNECTION"
      def simultaneous(*args)
        start_simultaneous
      end

      # A shorter name for the 'simultaneous' task is useful (Foreman appends
      # it to each line of output)
      map %w(bg publish tasks) => :simultaneous

      private

      def launch(processes)
        root   = File.expand_path(options.site)
        engine = ::Foreman::Engine::CLI.new(root: options.site)

        processes.each do |process|
          engine.register(process, "#{binary} server #{process} --root=#{root}")
        end
        site = prepare! :start

        output_dir = site.paths(:compiled_assets).first
        site.development_watchers.each do |name, cmd|
          engine.register(name, p(cmd.call(output_dir)))
        end

        engine.start
      end

      def binary
        ::Spontaneous.gem_dir("bin/spot")
      end

      def start_server(mode)
        site = prepare! :server, mode
        Spontaneous::Server.run!(site, options)
      end

      def start_simultaneous
        prepare! :start
        connection = options[:connection] || ::Spontaneous.config.simultaneous_connection
        exec({"BUNDLE_GEMFILE" => nil}, "#{::Simultaneous.server_binary} -c #{connection} --debug")
      end
    end
  end
end

