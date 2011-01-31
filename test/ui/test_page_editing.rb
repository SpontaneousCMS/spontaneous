# encoding: UTF-8

require 'test_helper'
require 'ui_helper'





class PageEditingTest < Test::Unit::TestCase
  include SeleniumTest

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
