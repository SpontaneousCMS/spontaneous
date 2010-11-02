# encoding: UTF-8

require 'test_helper'


class ExtensionsTest < Test::Unit::TestCase
  context "String" do
    should "create paths with String#/" do
      ("this" / "that").should == "this/that"
      ("/this" / "/that").should == "/this/that"
    end
  end
end

