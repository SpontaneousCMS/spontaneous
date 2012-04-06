# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ExtensionsTest < MiniTest::Spec
  context "String" do
    should "create paths with String#/" do
      ("this" / "that").should == "this/that"
      ("/this" / "/that").should == "/this/that"
    end
  end

  context "Nil" do
    should "always return the argument for the slash switch" do
      (nil / "something").should == "something"
    end
  end

  context "Enumerable" do
    should "correctly slice_between elements" do
      result = ["js", "coffee", "coffee", "js", "coffee"].slice_between { |prev, current| prev != current }.to_a
      result.should == [["js"], ["coffee", "coffee"], ["js"], ["coffee"]]
    end
  end
end

