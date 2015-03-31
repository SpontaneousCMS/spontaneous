require 'syslog/logger'

module Spontaneous::Publishing::Progress
  class Syslog < Silent

    include LoggerOutput

    def initialize(program_name = 'spontaneous-publishing', facility = ::Syslog::LOG_LOCAL0)
      super()
      require 'syslog/logger'
      @logger = ::Syslog::Logger.new(program_name, facility)
    end
  end
end
