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

    def self.retrieve(name)
      case (klass = registered[name])
      when nil
        nil
      when Class
        klass
      when Symbol, String
        const_get(klass)
      end
    end

    def self.register(klass, *names)
      names.each do |name|
        registered[name] = klass
      end
    end

    class Progress
    end

    module LoggerOutput
      def log(message)
        super
        @logger.info(message)
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
    end

    autoload :Log, 'spontaneous/publishing/progress/log'
    autoload :Multi, 'spontaneous/publishing/progress/multi'
    autoload :Silent, 'spontaneous/publishing/progress/silent'
    autoload :Simultaneous, 'spontaneous/publishing/progress/simultaneous'
    autoload :Stdout, 'spontaneous/publishing/progress/stdout'
    autoload :Syslog, 'spontaneous/publishing/progress/syslog'

    register :Log, :log
    register :Silent, :silent, :none
    register :Simultaneous, :simultaneous, :browser
    register :Stdout, :stdout
    register :Syslog, :syslog
  end
end
