module Spontaneous::Publishing::Progress
  class Stdout < Log

    def initialize
      super($stdout)
    end
  end
end

