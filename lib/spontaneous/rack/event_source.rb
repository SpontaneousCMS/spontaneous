# encoding: UTF-8

module Spontaneous
  module Rack
    class EventSource < ::Simultaneous::Rack::EventSource
      def push(client)
        @lock.synchronize { @clients << client }
      end

      alias_method :<<, :push

      def delete(client)
        @lock.synchronize { removed = @clients.delete(client) }
      end
    end
  end
end
