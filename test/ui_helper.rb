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
  @@browser = nil

  def browser
    @@browser
  end

  module ClassMethods
    def browser
      @@browser
    end

    def startup
      Spontaneous::Permissions::User.delete
      @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass", :password_confirmation => "rootpass")
      @user.update(:level => Spontaneous::Permissions.root)
      @user.save
      launch_selenium
      launch_site
      @@browser = Selenium::Client::Driver.new(
        :host => "localhost",
        :port => SELENIUM_PORT,
        :browser => "*firefox",
        # :browser => "*firefox3/Applications/Firefox/Firefox3_5.app/Contents/MacOS/firefox-bin",
        # :browser => "*chrome/Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome",
        :url => "http://localhost:2011/",
        :timeout_in_second => 60
      )
      # @@browser.start_new_browser_session
    end

    def shutdown
      # @@browser.close_current_browser_session
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
        puts "\n>>> Launching selenium #{SELENIUM_BIN}"
        @_selenium_pid = fork do
          STDOUT.reopen("/dev/null")
          STDERR.reopen("/dev/null")
          exec("java -jar #{SELENIUM_BIN} -port #{SELENIUM_PORT}")
        end
        running, sock = false, nil
        waiting, max_wait = 0, 8

        print "  > Waiting for Selenium server."
        catch :giveup do
          begin
            begin
              sock = TCPSocket.open('127.0.0.1', SELENIUM_PORT)
              running = true
            rescue Errno::ECONNREFUSED
              print "."
              $stdout.flush
              running = false
              waiting += 1
              throw :giveup if waiting >= max_wait
              sleep(2)
            ensure
              sock.close if sock
            end
          end while !running
          puts "\n>>> Selenium running on port #{SELENIUM_PORT} PID #{@_selenium_pid}"
        end
        unless running
          puts ">>> Failed to start Selenium server\n>>> Does #{SELENIUM_BIN} exist?"
          exit(1)
        end
      end
    end

    def kill_selenium
      if @_selenium_pid
        puts "\n>>> Killing selenium PID #{@_selenium_pid}"
        Process.kill("TERM", @_selenium_pid)
      end
    end
  end # ClassMethods

  def setup
    @browser = self.class.browser
    self.class.browser.start_new_browser_session
  end

  def teardown
      self.class.browser.close_current_browser_session
  end

end

