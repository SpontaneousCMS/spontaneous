# encoding: UTF-8

require 'test_helper'
require 'ui_helper'





class PageEditingTest < Test::Unit::TestCase
  def self.startup
    launch_selenium
  end
  def self.shutdown
    kill_selenium
  end

  def self.suite
    mysuite = super
    def mysuite.run(*args)
      PageEditingTest.startup()
      super
      PageEditingTest.shutdown()
    end
    mysuite
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

  context "Page attributes" do
    should "set the editor title when page title changed" do
      new_title = "Updated #{Time.now.to_i}"
      @browser.open("/@spontaneous#/1@edit")
      @browser.wait_for_element("css=#page-fields")
      @browser.click("css=#page-fields")
      @browser.wait_for_element('css=#editing')
      @browser.type('name=field[title][unprocessed_value]', new_title)
      @browser.click("css=#dialogue-controls .button.save")
      @browser.wait_for_not_visible('dialogue-body')
      @browser.text('css=#page-info h1').should == new_title
    end
  end
end
