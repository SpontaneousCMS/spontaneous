require 'spontaneous/simultaneous'

module Spontaneous::Rack::Back
  class Events < Base
    def self.messenger
      @messenger ||= build_messenger
    end

    def self.build_messenger
      messenger = ::Spontaneous::Rack::EventSource.new
      # Find a way to move this into a more de-centralised place
      # at some point we are going to want to have some configurable, extendable
      # list of event handlers
      ::Simultaneous.on_event("publish_progress") { |event|
        messenger.deliver_event(event)
      }
      ::Simultaneous.on_event("page_lock_status") { |event|
        messenger.deliver_event(event)
      }
      messenger
    end

    get '/?', :provides => 'text/event-stream' do
      headers 'X-Accel-Buffering' =>  'no'
      stream(:keep_open) do |out|
        messenger = self.class.messenger
        out.errback  { messenger.delete(out) }
        out.callback { messenger.delete(out) }
        messenger << out
      end
    end
  end
end
