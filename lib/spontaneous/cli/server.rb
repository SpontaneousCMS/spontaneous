# encoding: UTF-8

# require 'spontaneous'
require 'simultaneous'
require 'foreman'
require 'foreman/engine'

module Spontaneous
  module Cli
    class Server < ::Thor
      include Spontaneous::Cli::TaskUtils

      namespace    :server
      default_task :start

      class_option :no_browser, :type => :boolean, :default => false, :aliases => "-b", :desc => "Don't launch browser"

      desc "start", "Starts Spontaneous in development mode"
      def start
        # I can do this programatically in the latest version of Foreman
        File.open(".Procfile", 'wb') do |procfile|
          procfile.write(%(back: #{binary} server back --root=#{options.site}\n))
          procfile.write(%(front: #{binary} server front --root=#{options.site}\n))
          procfile.write(%(simultaneous: #{binary} server simultaneous --root=#{options.site}\n))
          procfile.flush
          engine = ::Foreman::Engine.new(procfile.path)
          engine.start
        end
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
        fork {
          ENV.delete("BUNDLE_GEMFILE")
          puts("#{Simultaneous.server_binary} -c #{connection} --debug")
          exec("#{Simultaneous.server_binary} -c #{connection} --debug")
          # sleep 10
        }
        Process.wait
      end

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

