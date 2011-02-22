# encoding: UTF-8

require 'test_helper'
require 'ui_helper'





class PageEditingTest < Test::Unit::TestCase
  include StartupShutdown
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

  context "Markdown text editor" do
    setup do
      @original_text = <<-ORIGINAL
This is line 1.

This is line 2. And this is line 2 too.
      ORIGINAL
      @browser.open("/@spontaneous#/1@edit")
      @browser.wait_for_element("css=#page-fields")
      @browser.click("css=#page-fields")
      @browser.wait_for_element('css=#field-description-1')
      @browser.type('name=field[description][unprocessed_value]', @original_text)
    end

    should "wrap selected text in bold delimiters" do
      _start = @original_text.index('line 1')
      _end   = _start + 6
      @browser.get_eval(<<-JS)
        var el = window.document.getElementById('field-description-1');
        el.selectionStart = #{_start};
        el.selectionEnd = #{_end};
      JS
      @browser.click("css=#editor-field-description-1 .md-toolbar a.bold")
      # @browser.wait_for_element("css=#nontingnhgd")
      @browser.value("css=#field-description-1").should == (<<-TXT).strip
This is __line 1__.

This is line 2. And this is line 2 too.
      TXT
      # puts @browser.get_eval('window.document.getElementById("field-description-1").selectionStart')
      # puts @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd')
    end

    should "not add bold markers around empty selection" do
      _start = @original_text.index('line 1')
      _end   = _start + 6
      @browser.get_eval(<<-JS)
        var el = window.document.getElementById('field-description-1');
        el.selectionStart = 0
        el.selectionEnd = 0
      JS
      @browser.click("css=#editor-field-description-1 .md-toolbar a.bold")
      @browser.value("css=#field-description-1").should == (<<-TXT).strip
This is line 1.

This is line 2. And this is line 2 too.
      TXT
    end
  end
end
