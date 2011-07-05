
# encoding: UTF-8

require 'test_helper'


class PrototypeSetTest < MiniTest::Spec
  class Super < Struct.new(:prototypes); end
  context "Prototype Sets" do
    setup do
      @one = "One"
      @two = "Two"
      @three = "Three"
      @one.stubs(:schema_id).returns("one_id")
      @two.stubs(:schema_id).returns("two_id")
      @three.stubs(:schema_id).returns("three_id")
      @set = Spontaneous::PrototypeSet.new
      @set['one'] = @one
      @set[:two] = @two
      @set[:three] = @three
    end

    should "enable hash-like access by name" do
      @set[:three].should == "Three"
    end

    should "enable array-like access by index" do
      @set[2].should == "Three"
    end

    should "have a list of names" do
      @set.keys.should == [:one, :two, :three]
      @set.names.should == [:one, :two, :three]
      @set.order.should == [:one, :two, :three]
    end

    should "have a list of values" do
      @set.values.should == ['One', 'Two', 'Three']
    end

    should "test for keys" do
      @set.key?(:one).should be_true
      @set.key?(:two).should be_true
    end

    should "enable access by schema id" do
      @set.id("two_id").should == @two
    end

    should "have externally settable ordering" do
      @set.order = [:three, :two]
      @set.order.should == [:three, :two, :one]
      @set.map { |name, val| name }.should == [:three, :two, :one]
    end

    should "allow multiple setting of the order" do
      @set.order = [:three, :two]
      @set.order.should == [:three, :two, :one]
      @set.order = [:one, :three]
      @set.order.should == [:one, :three, :two]
    end

    should "have a hash-like map function" do
      @set.map { |name, val| [name, val] }.should == [[:one, "One"], [:two, "Two"], [:three, "Three"]]
    end

    should "have a hash-like each function" do
      keys = []
      @set.each { |name, val| keys << name }
      keys.should == [:one, :two, :three]
    end

    context "with superset" do
      setup do
        @superset = @set.dup
        @superset.order = [:three, :one, :two]
        @super = Super.new
        @super.prototypes = @superset
        @set = Spontaneous::PrototypeSet.new(@super, :prototypes)
        @four = "Four"
        @five = "Five"
        @four.stubs(:schema_id).returns("four_id")
        @five.stubs(:schema_id).returns("five_id")
        @set[:four] = @four
        @set[:five] = @five
      end
      teardown do
      end

      should "inherit values from a super-set" do
        @set[:one].should == "One"
        @set[:five].should == "Five"
      end

      should "test for keys" do
        @set.key?(:one).should be_true
        @set.key?(:five).should be_true
      end

      should "enable array-like access by index" do
        @set[3].should == "Four"
        @set[0].should == "Three"
      end

      should "have a list of names" do
        @set.names.should == [:three, :one, :two, :four, :five]
        @set.keys.should == [:three, :one, :two, :four, :five]
      end

      should "enable access by schema id" do
        @set.id("two_id").should == @two
        @set.id("four_id").should == @four
      end

      should "have externally settable ordering" do
        @set.order = [:five, :three, :two]
        @set.order.should == [:five, :three, :two, :one, :four]
        @set.map { |name, val| name }.should == [:five, :three, :two, :one, :four]
        @set.values.should == ['Five', 'Three', 'Two', 'One', 'Four']
      end

      should "have a hash-like map function" do
        @set.map { |name, val| [name, val] }.should == [[:three, "Three"], [:one, "One"], [:two, "Two"], [:four, "Four"], [:five, "Five"]]
      end

      should "have a hash-like each function" do
        keys = []
        @set.each { |name, val| keys << name }
        keys.should == [:three, :one, :two, :four, :five]
      end

      should "ignore a nil superobject" do
        set = Spontaneous::PrototypeSet.new(nil, :prototypes)
        set[:four] = @four
        set[:five] = @five
        set[:four].should == @four
        set[:two].should be_nil
        set.order.should == [:four, :five]
      end

      should "have a list of values" do
        @set.values.should == ['Three', 'One', 'Two', 'Four', 'Five']
      end
    end
  end
end

