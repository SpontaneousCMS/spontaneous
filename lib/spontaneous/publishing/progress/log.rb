module Spontaneous::Publishing::Progress
  class Log < Silent

    include LoggerOutput

    def initialize(io = $stdout, label = "Publish")
      super()
      # don't call close on stdout or stderr
      @closable = !((io == STDOUT) || (io == STDERR))
      @logger = Logger.new(io, File::APPEND)
      @logger.formatter = proc do |severity, datetime, progname, msg|
        pct = ("%03.2f" % [percentage]).rjust(6, " ")
        "#{label}:#{severity}: [#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')}] #{duration} #{pct}% #{current_stage} #{msg}\n"
      end
    end

    def done
      @logger.close if @closable
    end
  end
end
