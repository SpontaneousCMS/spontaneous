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

      class_option :no_browser, :type => :boolean, :default => false, :aliases => "-b", :desc => "Don't launch browser"

      desc "start", "Starts Spontaneous in development mode"
      def start
        root   = File.expand_path(options.site)
        engine = ::Foreman::Engine::CLI.new(root: options.site)

        %w(back front publish).each do |process|
          engine.register(process, "#{binary} server #{process} --root=#{root}")
        end

        engine.start
      end

      desc "front", "Starts Spontaneous in front/public mode"
      # method_option :adapter, :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host, :type => :string,  :aliases => "-h", :desc => "Bind to HOST address"
      method_option :port, :type => :numeric, :aliases => "-p", :desc => "Use PORT"
      def front
        start_server(:front)
      end

      desc "back", "Starts Spontaneous in back/CMS mode"
      # method_option :adapter, :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host, :type => :string,  :aliases => "-h", :desc => "Bind to HOST address"
      method_option :port, :type => :numeric, :aliases => "-p", :desc => "Use PORT"
      def back
        start_server(:back)
      end

      desc "simultaneous", "Launches the Simultaneous server"
      method_option :connection, :type => :string, :aliases => "-c", :desc => "Use CONNECTION"
      def simultaneous
        prepare! :start
        connection = options[:connection] || ::Spontaneous.config.simultaneous_connection
        exec({"BUNDLE_GEMFILE" => nil}, "#{Simultaneous.server_binary} -c #{connection} --debug")
      end

      # A shorter name for the 'simultaneous' task is useful (Foreman appends
      # it to each line of output)
      map %w(bg publish) => :simultaneous

      private

      def binary
        ::Spontaneous.gem_dir("bin/spot")
      end

      def start_server(mode)
        prepare! :server, mode
        Spontaneous::Server.run!(options)
      end

    end
  end
end

