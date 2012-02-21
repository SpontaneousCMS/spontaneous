require 'socket'
require 'net/http'

module Spontaneous
  module Publishing
    # a simple UNIX socket capable HTTP client used to send progress events
    # from the publish task to the back server (for forwarding onto clients)
    class EventClient
      def initialize(server_address)
        @server_address = server_address
      end

      def send_event(event_name, event_message)
        socket = open_socket
        return if socket.nil?
        sock = Net::BufferedIO.new(socket)
        request = request(event_name, event_message)
        # Host is a required header, but it doesn't matter to us what it is
        request["Host"] = "localhost"
        request.exec(sock, "1.1", request.path)
      ensure
        sock.close if sock
      end

      def request(event_name, event_message)
        query = ::Rack::Utils.build_nested_query({
          "event" => event_name,
          "data"  => event_message.to_json
        })
        Net::HTTP::Put.new("/@spontaneous/event?#{query}")
      end


      def open_socket
        return nil if @server_address.nil?
        case @server_address
        when /\//
          UNIXSocket.new(@server_address)
        else
          host, port = @server_address.split(":")
          TCPSocket.new(host, port)
        end
      end
    end
  end
end
