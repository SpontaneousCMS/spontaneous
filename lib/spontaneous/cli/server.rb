# encoding: UTF-8

require 'spontaneous'
require 'simultaneous'
require 'foreman'
require 'foreman/engine'

module Spontaneous
  module Cli
    class Server < ::Spontaneous::Cli::Thor
      namespace :server

      default_task :start

      # desc :start, "Starts Spontaneous"

      # def both
      #   pids = []
      #   trap(:INT) { }
      #   pids << fork { front }
      #   pids << fork { back }
      #   Process.wait
      #   pids.each { | pid | Process.kill(:TERM, pid) rescue nil }
      # end


      desc "#{namespace}:start", "Starts Spntaneous in development mode"
      def start
        File.open(".Procfile", 'wb') do |procfile|
          procfile.write(%(back: #{binary} server:back\n))
          procfile.write(%(front: #{binary} server:front\n))
          procfile.write(%(simultaneous: #{binary} server:simultaneous\n))
          procfile.flush
          puts File.read(procfile.path)
          engine = ::Foreman::Engine.new(procfile.path)
          engine.start
        end
      end

      desc "#{namespace}:front", "Starts Spontaneous in front/public mode"
      # method_option :adapter, :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host, :type => :string,  :aliases => "-h", :desc => "Bind to HOST address"
      method_option :port, :type => :numeric, :aliases => "-p", :desc => "Use PORT"
      def front
        start_server(:front)
      end

      desc "#{namespace}:back", "Starts Spontaneous in back/CMS mode"
      # method_option :adapter, :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      method_option :host, :type => :string,  :aliases => "-h", :desc => "Bind to HOST address"
      method_option :port, :type => :numeric, :aliases => "-p", :desc => "Use PORT"
      def back
        start_server(:back)
      end

      desc "#{namespace}:simultaneous", "Launches the Simultaneous server"
      method_option :connection, :type => :string, :aliases => "-c", :desc => "Use CONNECTION"
      def simultaneous
        prepare(:start)
        boot!
        connection = options[:connection] || ::Spontaneous.config.simultaneous_connection
        fork {
          puts("#{Simultaneous.server_binary} -c #{connection}")
          exec("#{Simultaneous.server_binary} -c #{connection}")
        }
        Process.wait
      end

      private

      def binary
        ::Spontaneous.gem_dir("bin/spot")
      end

      def start_server(mode)
        prepare mode.to_sym
        ENV["SPOT_MODE"] = mode.to_s
        require File.expand_path(File.dirname(__FILE__) + "/adapter")
        boot!
        Spontaneous::Cli::Adapter.start(options)
      end

    end
  end
end

