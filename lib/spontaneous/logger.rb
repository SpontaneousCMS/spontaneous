# encoding: UTF-8

## Adapted from Padrino::Logger
#
# Defines our SPOT_LOG_LEVEL
SPOT_LOG_LEVEL = ENV['SPOT_LOG_LEVEL'] unless defined?(SPOT_LOG_LEVEL)

module Spontaneous

  ##
  # Returns the spontaneous logger
  #
  # ==== Examples
  #
  #   logger.debug "foo"
  #   logger.warn "bar"
  #
  def self.logger
    Thread.current[:spontaneous_logger] ||= Spontaneous::Logger.setup!
  end

  def self.logger=(logger)
    Thread.current[:spontaneous_logger] = logger
  end

  ##
  # Extensions to the built in Ruby logger.
  #
  # ==== Examples
  #
  #   logger.debug "foo"
  #   logger.warn  "bar"
  #
  class Logger

    attr_accessor :level
    attr_accessor :auto_flush
    attr_reader   :buffer
    attr_reader   :log
    attr_reader   :init_args

    ##
    # Ruby (standard) logger levels:
    #
    # :fatal:: An unhandleable error that results in a program crash
    # :error:: A handleable error condition
    # :warn:: A warning
    # :info:: generic (useful) information about system operation
    # :debug:: low-level information for developers
    #
    Levels = {
      :fatal => 7,
      :error => 6,
      :warn  => 4,
      :info  => 3,
      :debug => 1,
      :trace => 0
    } unless const_defined?(:Levels)

    @@mutex = {}

    ##
    # Configuration for a given environment, possible options are:
    #
    # :log_level:: Once of [:fatal, :error, :warn, :info, :debug]
    # :stream:: Once of [:to_file, :null, :stdout, :stderr] our your custom stream
    # :log_level::
    #   The log level from, e.g. :fatal or :info. Defaults to :debug in the
    #   production environment and :debug otherwise.
    # :auto_flush::
    #   Whether the log should automatically flush after new messages are
    #   added. Defaults to true.
    # :format_datetime:: Format of datetime. Defaults to: "%d/%b/%Y %H:%M:%S"
    # :format_message:: Format of message. Defaults to: ""%s - - [%s] \"%s\"""
    #
    # ==== Examples
    #
    #   Spontaneous::Logger::Config[:development] = { :log_level => :debug, :to_file }
    #   # or you can edit our defaults
    #   Spontaneous::Logger::Config[:development][:log_level] = :error
    #   # or you can use your stream
    #   Spontaneous::Logger::Config[:development][:stream] = StringIO.new
    #
    # Defaults are:
    #
    #   :production  => { :log_level => :warn, :stream => :to_file }
    #   :development => { :log_level => :debug, :stream => :stdout }
    #   :test        => { :log_level => :fatal, :stream => :null }
    #
    Config = {
      :production  => { :log_level => :warn,  :stream => :to_file },
      :development => { :log_level => :debug, :stream => :stdout },
      :test        => { :log_level => :debug, :stream => :null },
      :gem         => { :log_level => :trace, :stream => :stdout }
    }

    # Embed in a String to clear all previous ANSI sequences.
    CLEAR      = "\e[0m"
    # The start of an ANSI bold sequence.
    BOLD       = "\e[1m"
    # Set the terminal's foreground ANSI color to black.
    BLACK      = "\e[30m"
    # Set the terminal's foreground ANSI color to red.
    RED        = "\e[31m"
    # Set the terminal's foreground ANSI color to green.
    GREEN      = "\e[32m"
    # Set the terminal's foreground ANSI color to yellow.
    YELLOW     = "\e[33m"
    # Set the terminal's foreground ANSI color to blue.
    BLUE       = "\e[34m"
    # Set the terminal's foreground ANSI color to magenta.
    MAGENTA    = "\e[35m"
    # Set the terminal's foreground ANSI color to cyan.
    CYAN       = "\e[36m"
    # Set the terminal's foreground ANSI color to white.
    WHITE      = "\e[37m"

    # Colors for levels
    ColoredLevels = {
      :fatal => [BOLD, RED],
      :error => [RED],
      :warn  => [YELLOW],
      :info  => [GREEN],
      :debug => [CYAN],
      :trace => []
    } unless defined?(ColoredLevels)

    ##
    # Setup a new logger
    #
    def self.setup!
      setup
    end

    ##
    # Setup a new logger with options
    #
    def self.setup(options = {})
      config_level = (SPOT_LOG_LEVEL || Spontaneous.env || :production).to_sym # need this for SPOT_LOG_LEVEL
      config = Config[config_level] || Config[:production]                     # default to a production level
      stream = \
        if logfile = options[:logfile]
          FileUtils.mkdir_p(File.dirname(logfile)) unless File.directory?(File.dirname(logfile))
          File.new(logfile, "a+")
        else
          case config[:stream]
          when :to_file
            FileUtils.mkdir_p(Spontaneous.root("log")) unless File.exists?(Spontaneous.root("log"))
            File.new(Spontaneous.root("log", "#{Spontaneous.env}.log"), "a+")
          when :null   then StringIO.new
          when :stdout then $stdout
          when :stderr then $stderr
          else config[:stream] # return itself, probabilly is a custom stream.
          end
        end
      config[:log_level] = options[:log_level] if options[:log_level]
      Spontaneous.logger = Spontaneous::Logger.new(config.merge(:stream => stream))
    end

    ##
    # To initialize the logger you create a new object, proxies to set_log.
    #
    # ==== Options
    #
    # :stream:: Either an IO object or a name of a logfile. Defaults to $stdout
    # :log_level::
    #   The log level from, e.g. :fatal or :info. Defaults to :debug in the
    #   production environment and :debug otherwise.
    # :auto_flush::
    #   Whether the log should automatically flush after new messages are
    #   added. Defaults to true.
    # :format_datetime:: Format of datetime. Defaults to: "%d/%b/%Y %H:%M:%S"
    # :format_message:: Format of message. Defaults to: ""%s - - [%s] \"%s\"""
    #
    def initialize(options={})
      @buffer            = []
      @auto_flush        = options.has_key?(:auto_flush) ? options[:auto_flush] : true
      @level             = options[:log_level] ? Levels[options[:log_level]] : Levels[:debug]
      @log               = options[:stream]  || $stdout
      @log.sync          = true
      @mutex             = @@mutex[@log] ||= Mutex.new
      @format_datetime   = options[:format_datetime] || "%d/%b/%Y %H:%M:%S"
      @format_message    = options[:format_message]  || "%s - [%s] %s"
    end

    ##
    # Colorize our level
    #
    def colored_level(level)
      style = ColoredLevels[level.to_s.downcase.to_sym].join("")
      "#{style}#{level.to_s.upcase.rjust(7)}#{CLEAR}"
    end

    ##
    # Set a color for our string. Color can be a symbol/string
    #
    def set_color(string, color, bold=false)
      color = self.class.const_get(color.to_s.upcase) if color.is_a?(Symbol)
      bold  = bold ? BOLD : ""
      "#{bold}#{color}#{string}#{CLEAR}"
    end

    ##
    # Flush the entire buffer to the log object.
    #
    def flush
      return unless @buffer.size > 0
      @mutex.synchronize do
        @log.write(@buffer.slice!(0..-1).join(''))
      end
    end

    ##
    # Close and remove the current log object.
    #
    def close
      flush
      @log.close if @log.respond_to?(:close) && !@log.tty?
      @log = nil
    end

    ##
    # Appends a message to the log. The methods yield to an optional block and
    # the output of this block will be appended to the message.
    #
    def push(message = nil, level = nil)
      unless @silent
        message = format_backtrace(message) if message.class < Error
        self << @format_message % [colored_level(level), set_color(Time.now.strftime(@format_datetime), :yellow), message.to_s.strip]
      end
    end

    def format_backtrace(error)
      [error.message].concat(error.backtrace).join("\n")
    end
    ##
    # Directly append message to the log.
    #
    def <<(message = nil)
      message << "\n" unless message[-1] == ?\n
      @buffer << message
      flush if @auto_flush
      message
    end

    ##
    # Generate the logging methods for Spontaneous.logger for each log level.
    #
    Levels.each_pair do |name, number|
      class_eval <<-LEVELMETHODS, __FILE__, __LINE__

      # Appends a message to the log if the log level is at least as high as
      # the log level of the logger.
      #
      # ==== Parameters
      # message:: The message to be logged. Defaults to nil.
      #
      # ==== Returns
      # self:: The logger object for chaining.
      def #{name}(message = nil)
        if #{number} >= level
          message = block_given? ? yield : message
          self.push(message, :#{name})
        end
        self
      end

      # Appends a message to the log if the log level is at least as high as
      # the log level of the logger. The bang! version of the method also auto
      # flushes the log buffer to disk.
      #
      # ==== Parameters
      # message:: The message to be logged. Defaults to nil.
      #
      # ==== Returns
      # self:: The logger object for chaining.
      def #{name}!(message = nil)
        if #{number} >= level
          message = block_given? ? yield : message
          self.push(message, :#{name})
          flush
        end
        self
      end

      # ==== Returns
      # Boolean:: True if this level will be logged by this logger.
      def #{name}?
        #{number} >= level
      end
      LEVELMETHODS
    end

    def silent!
      @silent = true
      if block_given?
        begin
          yield
        ensure
          @silent = false
        end
      end
    end

    alias_method :pause!, :silent!

    def silent?
      @silent
    end

    def resume!
      @silent = false
    end
    ##
    # Spontaneous::Loggger::Rack forwards every request to an +app+ given, and
    # logs a line in the Apache common log format to the +logger+, or
    # rack.errors by default.
    #
    class Rack
      ##
      # Common Log Format: http://httpd.apache.org/docs/1.3/logs.html#common
      # "lilith.local - - GET / HTTP/1.1 500 -"
      #  %{%s - %s %s %s%s %s - %d %s %0.4f}
      #
      FORMAT = %{%s - %s %s %s%s %s - %d %s %0.4f}

      def initialize(app)
        @app = app
      end

      def call(env)
        began_at = Time.now
        status, header, body = @app.call(env)
        log(env, status, header, began_at)
        [status, header, body]
      end

      private
        def log(env, status, header, began_at)
          now = Time.now
          length = extract_content_length(header)

          logger.debug FORMAT % [
            env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
            env["REMOTE_USER"] || "-",
            env["REQUEST_METHOD"],
            env["PATH_INFO"],
            env["QUERY_STRING"].empty? ? "" : "?" + env["QUERY_STRING"],
            env["HTTP_VERSION"],
            status.to_s[0..3],
            length,
            now - began_at ]
        end

        def extract_content_length(headers)
          headers.each do |key, value|
            if key.downcase == 'content-length'
              return value.to_s == '0' ? '-' : value
            end
          end
          '-'
        end
    end # Rack
  end # Logger
end # Spontaneous

module Kernel #:nodoc:
  ##
  # Define a logger available every where in our app
  #
  def logger
    Spontaneous.logger
  end
end # Kernel
