require "selenium/client"

# should now set up a site and launch the back server

# in order for this to work (at least on my machine/setup - os x 10.6) you need to
# put the version of Firefox that you want to use into /Applications/Firefox.app
# anywhere else or any other name and it won't work
SELENIUM_BIN = ENV['SELENIUM_BIN'] || '../selenium-server-standalone-2.0b1.jar'
SELENIUM_PORT = ENV['SELENIUM_PORT'] || 4444

module SeleniumTest
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def startup
      launch_selenium
      launch_site
    end

    def shutdown
      kill_selenium
      kill_site
    end

    def launch_site
      puts "TODO: Launch & initialise site"
    end

    def kill_site
      puts "TODO: kill site"
    end

    def launch_selenium
      if !@_selenium_pid
        puts "Launching selenium #{SELENIUM_BIN}"
        @_selenium_pid = fork do
          STDOUT.reopen("/dev/null")
          exec("java -jar #{SELENIUM_BIN} -port #{SELENIUM_PORT}")
        end
        running = false
        sock = nil
        begin
          sleep(1)
          begin
            sock = TCPSocket.open('127.0.0.1', SELENIUM_PORT)
            running = true
          rescue Errno::ECONNREFUSED
            puts "Waiting for Selenium server..."
            running = false
            sleep(1)
          ensure
            sock.close if sock
          end
        end while !running
        puts "Selenium running on port #{SELENIUM_PORT} PID #{@_selenium_pid}"
      end
    end

    def kill_selenium
      if @_selenium_pid
        puts "Killing selenium PID #{@_selenium_pid}"
        Process.kill("TERM", @_selenium_pid)
      end
    end

    def suite
      mysuite = super
      def mysuite.run(*args)
        PageEditingTest.startup()
        begin
          super
        ensure
          PageEditingTest.shutdown()
        end
      end
      mysuite
    end

  end

  def setup
    @browser = Selenium::Client::Driver.new(
      :host => "localhost",
      :port => SELENIUM_PORT,
      :browser => "*firefox",
      # :browser => "*firefox3/Applications/Firefox/Firefox3_5.app/Contents/MacOS/firefox-bin",
      # :browser => "*chrome/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome",
      :url => "http://localhost:2011/",
      :timeout_in_second => 60
    )
    @browser.start_new_browser_session
  end

  def teardown
    @browser.close_current_browser_session
  end

end

