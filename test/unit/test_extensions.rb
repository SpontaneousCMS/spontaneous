# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Extensions" do
  describe "String" do
    it  "create paths with String#/" do
      ("this" / "that").must_equal "this/that"
      ("/this" / "/that").must_equal "/this/that"
    end

    it  "override the | method to return the argument if empty" do
      ("" | "that").must_equal "that"
      ("this" | "that").must_equal "this"
    end

    it  "override the or method to return the argument if empty" do
      ("".or("that")).must_equal "that"
      ("this".or("that")).must_equal "this"
    end

    it  "return self for #value" do
      "this".value.must_equal "this"
      "this".value(:html).must_equal "this"
      "this".value(:smsx).must_equal "this"
    end
  end

  describe "Nil" do
    it  "always return the argument for the slash switch" do
      (nil / "something").must_equal "something"
    end
    it  "always return the argument for the #or switch" do
      (nil.or("something")).must_equal "something"
    end
  end

  describe "Enumerable" do
    it  "correctly slice_between elements" do
      result = ["js", "coffee", "coffee", "js", "coffee"].slice_between { |prev, current| prev != current }.to_a
      result.must_equal [["js"], ["coffee", "coffee"], ["js"], ["coffee"]]
    end
  end

  describe "Array" do
    it 'responds to #render by calling #render_inline on the contents' do
      array = 3.times.map { mock }
      array.each do |m|
        m.expects(:render_inline).returns("x")
      end
      array.render.must_equal 'xxx'
    end
    it 'responds to #render_using by calling #render_inline_using on the contents' do
      array = 3.times.map { mock }
      array.each do |m|
        m.expects(:render_inline_using).returns("x")
      end
      array.render_using(mock).must_equal 'xxx'
    end
  end
end

