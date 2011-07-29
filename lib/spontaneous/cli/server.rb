
module Spontaneous
  module Cli
    class Server < ::Spontaneous::Cli::Thor
      namespace :server

      default_task :back

      # desc :start, "Starts Spontaneous"
      # method_option :adapter, :type => :string,  :aliases => "-a", :desc => "Rack Handler (default: autodetect)"
      # method_option :host, :type => :string,  :aliases => "-h", :desc => "Bind to HOST address"
      # method_option :port, :type => :numeric, :aliases => "-p", :desc => "Use PORT"

      # def both
      #   pids = []
      #   trap(:INT) { }
      #   pids << fork { front }
      #   pids << fork { back }
      #   Process.wait
      #   pids.each { | pid | Process.kill(:TERM, pid) rescue nil }
      # end


      desc "#{namespace}:front", "Starts Spontaneous in front/public mode"
      def front
        start_server(:front)
      end

      desc "#{namespace}:back", "Starts Spontaneous in back/CMS mode"
      def back
        start_server(:back)
      end

      private

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

