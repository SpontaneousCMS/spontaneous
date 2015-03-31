module Spontaneous::Publishing::Progress
  class Multi < Progress
    def initialize(*outputs)
      @outputs = outputs
    end

    def log(message)
      @outputs.each { |progress| progress.log(message) }
    end

    def start(total_steps)
      @outputs.each { |progress| progress.start(total_steps) }
    end

    def stage(name)
      @outputs.each { |progress| progress.stage(name) }
    end

    def step(n = 1, msg = "")
      @outputs.each { |progress| progress.step(n, msg) }
    end

    def error(exception)
      @outputs.each { |progress| progress.error(exception) }
    end

    def done
      @outputs.each { |progress| progress.done }
    end
  end
end
