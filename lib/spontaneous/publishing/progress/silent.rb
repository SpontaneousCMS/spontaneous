module Spontaneous::Publishing::Progress
  class Silent < Progress
    attr_reader :total, :stage

    def initialize
      @total = 0
      @position  = 0
      @stage = ""
      @start = Time.now
    end

    def start(total_steps)
      @total = total_steps
    end

    def stage(name)
      @stage = name
    end

    def current_stage
      @stage
    end

    def step(n = 1, msg = "")
      @position += n
    end

    def log(message)
    end

    def error(exception)
    end

    def done
    end

    def percentage
      return 0.0 if @position == 0
      ((@position.to_f / @total.to_f) * 100).round(2)
    end

    def position
      @position
    end

    def duration
      Duration.new(Time.now - @start)
    end
  end
end
