# encoding: UTF-8

# Rack::Handler.register('unicorn', 'Unicorn') if defined?(Unicorn)

## thanks again to the stirling work of the Padrino guys & gals.
require 'rack'

module Spontaneous

  module Server

    Handlers = %w[thin] unless const_defined?(:Handlers)


    def self.run!(options={})
      host = options["host"] || Site.config.host || "0.0.0.0"
      port = options["port"] || Site.config.port || 2012
      adapter = options["adapter"] || Site.config.adapter

      handler = nil

      if adapter
        begin
          handler = ::Rack::Handler.get(adapter.downcase)
        rescue => e
          puts e
          puts e.backtrace
          raise LoadError, "Rack handler #{adapter} not supported. Please use one of #{Handlers.join(', ')}"
          exit
        end
      else
        handler = detect_handler
      end
      puts "=> Spontaneous:#{Spontaneous.mode.to_s.ljust(5, " ")} running on port #{host}:#{port} (PID #{$$})"

      handler.run Spontaneous::Rack.application.to_app, :Host => host, :Port => port do |server|
        term = Proc.new do
          server.respond_to?(:stop!) ? server.stop! : server.stop
          puts "=> Spontaneous:#{Spontaneous.mode.to_s.ljust(5, " ")} exiting..."
        end
        trap(:INT, &term)
        trap(:TERM, &term)
      end
    rescue RuntimeError => e
      if e.message =~ /no acceptor/
        puts "=> Unable to run server, port #{port} is already in use"
      else
        raise e
      end
    rescue Errno::EADDRINUSE
      puts "=> Unable to run server,  port #{port} is already in use"
    end

    def self.detect_handler
      Handlers.each do |handler_name|
        begin
          return ::Rack::Handler.get(handler_name.downcase)
        rescue Exception => e
          puts e
          puts e.backtrace
        end
      end
      raise LoadError, "No handlers available: #{Handlers.join(', ')}"
    end
  end # Server
end # Spontaneous

