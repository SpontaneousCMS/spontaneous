require 'logger'
require 'delegate'
require 'simultaneous'

module Spontaneous::Publishing
  module Progress
    class Duration < DelegateClass(Float)
      def to_s
        d = self.to_f
        h, r = _factor(d, 3600)
        m, _ = _factor(r, 60)
        s = (d - (h*3600 + m * 60)).round(2)
        "%02dh %02dm %02.2fs" % [h, m,s]
      end

      def _factor(d, f)
        [d.to_i/f, d.to_i%f]
      end
    end

    def self.registered
      @registered ||= {}
    end

    class Progress
      def self.register(klass, *names)
        names.each do |name|
          Spontaneous::Publishing::Progress.registered[name] = klass
        end
      end
    end

    class Silent < Progress
      attr_reader :total, :stage

      register self, :silent, :none

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
        ((@position.to_f / @total.to_f) * 100).round(2)
      end

      def position
        @position
      end

      def duration
        Duration.new(Time.now - @start)
      end
    end

    class Log < Silent
      register self, :log

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

      def log(message)
        super
        logger.info(message)
      end

      def step(n = 1, msg = "")
        super
        @logger.info("#{msg}")
      end

      def error(exception)
        super
        msg = [exception.to_s].concat(exception.backtrace).join("\n")
        @logger.error(msg)
      end

      def done
        @logger.close if @closable
      end
    end

    class Stdout < Log
      register self, :stdout

      def initialize
        super($stdout)
      end
    end

    class Simultaneous < Silent
      register self, :simultaneous, :browser

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
end
