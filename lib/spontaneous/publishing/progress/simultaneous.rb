module Spontaneous::Publishing::Progress
  class Simultaneous < Silent

    def stage(name)
      super
      send_event
    end

    def step(n = 1, msg = "")
      super
      send_event
    end

    def send_event(stage = current_stage, _percentage = percentage)
      ::Simultaneous.send_event('publish_progress', {:state => stage, :progress => _percentage}.to_json)
    rescue Errno::ECONNREFUSED
    rescue Errno::ENOENT
    end

    def error(exception)
      super
      send_event("aborting", "*")
    end

    def done
      super
      send_event("complete", "*")
    end
  end
end
