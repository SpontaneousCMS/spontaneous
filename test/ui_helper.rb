require "selenium/client"

# should now set up a site and launch the back server

# in order for this to work (at least on my machine/setup - os x 10.6) you need to
# put the version of Firefox that you want to use into /Applications/Firefox.app
# anywhere else or any other name and it won't work
SELENIUM_BIN = ENV['SELENIUM_BIN'] || '../selenium-server-standalone-2.0b1.jar'
SELENIUM_PORT = ENV['SELENIUM_PORT'] || 4444

def launch_selenium
  if !@_selenium_pid
    puts "Launching selenium #{SELENIUM_BIN}"
    @_selenium_pid = fork do
      exec("java -jar #{SELENIUM_BIN} -port #{SELENIUM_PORT} >/dev/null")
    end
    running = false
    begin
      sleep(1)
      begin
        sock = TCPSocket.open('127.0.0.1', SELENIUM_PORT)
        running = true
      rescue Errno::ECONNREFUSED
        puts "Waiting for Selenium server..."
        running = false
        sleep(1)
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
