
module Spontaneous
  module Rack
    class SSE
      attr_reader :event, :data

      def initialize(params)
        @event = params[:event]
        @data  = params[:data]
      end

      def to_sse
        lines = ["event: #{event}", "data: #{data}", "\n"]
        lines.join("\n")
      end
    end
  end
end
