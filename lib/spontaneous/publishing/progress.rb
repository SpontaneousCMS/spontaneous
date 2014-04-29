require 'logger'
require 'delegate'
require 'simultaneous'

module Spontaneous::Publishing
  module Progress
    class Duration < DelegateClass(Float)
      def to_s
        d = self.to_i
        h, d = _factor(d, 3600)
        m, s = _factor(d, 60)
        str = (h > 0) ? "#{h}h " : ""
        str << "#{m}m #{s}s"
      end

      def _factor(d, f)
        [d/f, d%f]
      end
    end

    class Silent
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
        ((@position.to_f / @total.to_f) * 100).round(1)
      end

      def position
        @position
      end

      def duration
        Duration.new(Time.now - @start)
      end
    end

    class Log < Silent
      def initialize(io, label = "Publish")
        super()
        # don't call close on stdout or stderr
        @closable = !((io == STDOUT) || (io == STDERR))
        @logger = Logger.new(io, File::APPEND)
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{label}:#{severity}: [#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N')}] #{stage} #{msg}\n"
        end
      end

      def log(message)
        super
        logger.info(message)
      end

      def step(n = 1, msg = "")
        super
        @logger.info("#{msg} #{percentage}%")
      end

      def error(exception)
      end

      def done
        @logger.close if @closable
      end
    end

    class Simultaneous < Silent

      def stage(name)
        super
        send_event
      end

      def step(n = 1, msg = "")
        super
        send_event
      end

      def send_event(percentage = percentage)
        ::Simultaneous.send_event('publish_progress', {:state => @stage, :progress => percentage}.to_json)
      rescue Errno::ECONNREFUSED
      rescue Errno::ENOENT
      end

      def error(exception)
        super
        send_event("*")
      end
    end

    class Multi
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
end
