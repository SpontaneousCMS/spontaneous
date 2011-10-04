# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ExtensionsTest < MiniTest::Spec
  context "String" do
    should "create paths with String#/" do
      ("this" / "that").should == "this/that"
      ("/this" / "/that").should == "/this/that"
    end
  end
end

