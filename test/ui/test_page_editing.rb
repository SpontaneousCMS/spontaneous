# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'ui_helper'





class PageEditingTest < MiniTest::Spec
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

  def select_text(_start, _end, _selector='field-description-1')
    @browser.get_eval(<<-JS)
        var el = window.document.getElementById('#{_selector}');
        el.selectionStart = #{_start};
        el.selectionEnd = #{_end};
    JS
  end

  context "Markdown text editor" do
    setup do
      @original_text = <<-ORIGINAL
This is line 1.

This is line 2. And this is line 2 too.

But this is line 3.
And this is line 4.
      ORIGINAL
      @browser.open("/@spontaneous#/1@edit")
      @browser.wait_for_element("css=#page-fields")
      @browser.click("css=#page-fields")
      @browser.wait_for_element('css=#field-description-1')
      @browser.type('name=field[description][unprocessed_value]', @original_text)
    end

    should "embolden text" do
      _start = @original_text.index('line 1')
      _end   = _start + 6
      select_text(_start, _end)
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.bold.active").should be_false
      @browser.click("css=#editor-field-description-1 .md-toolbar a.bold")
      # @browser.wait_for_element("css=#nontingnhgd")
      @browser.value("css=#field-description-1").should == (<<-TXT).strip
This is **line 1**.

This is line 2. And this is line 2 too.

But this is line 3.
And this is line 4.
      TXT
      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _start + 10
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.bold.active").should be_true

      @browser.click("css=#editor-field-description-1 .md-toolbar a.bold")
      @browser.value("css=#field-description-1").should == @original_text.strip
      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _end
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.bold.active").should be_false
    end

    should "italicise text" do
      _start = @original_text.index('this is line 2')
      _end   = _start + 14
      select_text(_start, _end)
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.italic.active").should be_false
      @browser.click("css=#editor-field-description-1 .md-toolbar a.italic")
      # @browser.wait_for_element("css=#nontingnhgd")
      @browser.value("css=#field-description-1").should == (<<-TXT).strip
This is line 1.

This is line 2. And _this is line 2_ too.

But this is line 3.
And this is line 4.
      TXT
      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _start + 16
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.italic.active").should be_true

      @browser.click("css=#editor-field-description-1 .md-toolbar a.italic")
      @browser.value("css=#field-description-1").should == @original_text.strip
      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _end
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.italic.active").should be_false
    end

    should "add headers" do
      _select = 'But this is line 3.'
      _start = @original_text.index(_select)
      _end   = _start + _select.length
      select_text(_start, _end)
      @browser.click("css=#editor-field-description-1 .md-toolbar a.h1")
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h1.active").should be_false
      # @browser.wait_for_element("css=#nontingnhgd")
      @browser.value("css=#field-description-1").should == (<<-TXT).strip
This is line 1.

This is line 2. And this is line 2 too.

But this is line 3.
==============================
And this is line 4.
      TXT
      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _end + 31
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h1.active").should be_true

      @browser.click("css=#editor-field-description-1 .md-toolbar a.h2")
      @browser.value("css=#field-description-1").should == (<<-TXT).strip
This is line 1.

This is line 2. And this is line 2 too.

But this is line 3.
------------------------------
And this is line 4.
      TXT
      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _end + 31
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h1.active").should be_false
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h2.active").should be_true

      @browser.click("css=#editor-field-description-1 .md-toolbar a.h2")
      @browser.value("css=#field-description-1").should == @original_text.strip
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h1.active").should be_false
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h2.active").should be_false

      @browser.get_eval('window.document.getElementById("field-description-1").selectionStart').to_i.should == _start
      @browser.get_eval('window.document.getElementById("field-description-1").selectionEnd').to_i.should == _end
      @browser.click("css=#editor-field-description-1 .md-toolbar a.h1")
      @browser.click("css=#editor-field-description-1 .md-toolbar a.h1")
      @browser.value("css=#field-description-1").should == @original_text.strip
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h1.active").should be_false
      # @browser.element?("css=#editor-field-description-1 .md-toolbar a.h2.active").should be_false
    end


    should "not alter empty selection" do
      select_text(0, 0)
      @browser.click("css=#editor-field-description-1 .md-toolbar a.bold")
      @browser.value("css=#field-description-1").should == @original_text.strip
      @browser.click("css=#editor-field-description-1 .md-toolbar a.italic")
      @browser.value("css=#field-description-1").should == @original_text.strip
      @browser.click("css=#editor-field-description-1 .md-toolbar a.h1")
      @browser.value("css=#field-description-1").should == @original_text.strip
      @browser.click("css=#editor-field-description-1 .md-toolbar a.h2")
      @browser.value("css=#field-description-1").should == @original_text.strip
    end
  end
end
