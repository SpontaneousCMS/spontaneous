# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ExtensionsTest < MiniTest::Spec
  context "String" do
    should "create paths with String#/" do
      ("this" / "that").should == "this/that"
      ("/this" / "/that").should == "/this/that"
    end

    should "override the | method to return the argument if empty" do
      ("" | "that").should == "that"
      ("this" | "that").should == "this"
    end

    should "override the or method to return the argument if empty" do
      ("".or("that")).should == "that"
      ("this".or("that")).should == "this"
    end
  end

  context "Nil" do
    should "always return the argument for the slash switch" do
      (nil / "something").should == "something"
    end
    should "always return the argument for the #or switch" do
      (nil.or("something")).should == "something"
    end
  end

  context "Enumerable" do
    should "correctly slice_between elements" do
      result = ["js", "coffee", "coffee", "js", "coffee"].slice_between { |prev, current| prev != current }.to_a
      result.should == [["js"], ["coffee", "coffee"], ["js"], ["coffee"]]
    end
  end
end

