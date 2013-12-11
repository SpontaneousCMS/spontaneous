# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "PrototypeSet" do
  class Super < Struct.new(:prototypes); end

  before do
    @one = "One"
    @two = "Two"
    @three = "Three"
    @one.stubs(:schema_id).returns("one_id")
    @two.stubs(:schema_id).returns("two_id")
    @three.stubs(:schema_id).returns("three_id")
    @set = Spontaneous::Collections::PrototypeSet.new
    @set['one'] = @one
    @set[:two] = @two
    @set[:three] = @three
  end

  it "return correct value for empty? test" do
    refute @set.empty?
    assert Spontaneous::Collections::PrototypeSet.new.empty?
  end

  it "return the last value" do
    @set.last.must_equal "Three"
  end

  it "enable hash-like access by name" do
    @set[:three].must_equal "Three"
    @set['three'].must_equal "Three"
  end

  it "know the number of entries" do
    @set.length.must_equal 3
    @set.count.must_equal 3
  end

  it "enable array-like access by index" do
    @set[2].must_equal "Three"
  end

  it "have a list of names" do
    @set.keys.must_equal [:one, :two, :three]
    @set.names.must_equal [:one, :two, :three]
    @set.order.must_equal [:one, :two, :three]
  end

  it "have a list of values" do
    @set.values.must_equal ['One', 'Two', 'Three']
  end

  it "test for keys" do
    assert @set.key?(:one)
    assert @set.key?(:two)
  end

  it "enable access by schema id" do
    @set.sid("two_id").must_equal @two
  end

  it "have externally settable ordering" do
    @set.order = [:three, :two]
    @set.order.must_equal [:three, :two, :one]
    @set.map { |val| val }.must_equal ['Three', 'Two', 'One']
  end

  it "allow multiple setting of the order" do
    @set.order = [:three, :two]
    @set.order.must_equal [:three, :two, :one]
    @set.order = [:one, :three]
    @set.order.must_equal [:one, :three, :two]
  end

  it "have a hash-like map function" do
    @set.map { |val| val }.must_equal ["One", "Two", "Three"]
  end

  it "have a hash-like each function" do
    keys = []
    @set.each { |val| keys << val }
    keys.must_equal ["One", "Two", "Three"]
  end

  it "allow access to values as method calls" do
    @set.one.must_equal "One"
    @set.three.must_equal "Three"
    lambda { @set.nine }.must_raise(NoMethodError)
  end

  it "uses the given block to set default values" do
    set = Spontaneous::Collections::PrototypeSet.new { |set, key| set[key] = key.to_s.upcase }
    set.key?(:one).must_equal false
    set[:one].must_equal "ONE"
    set.keys.must_equal [:one]
  end

  describe "with superset" do
    before do
      @superset = @set.dup
      # give the superset a custom order to make sure it propagates to the child set
      @superset.order = [:three, :one, :two]
      @super = Super.new
      @super.prototypes = @superset
      @set = Spontaneous::Collections::PrototypeSet.new(@super, :prototypes) { |set, key| set[key] = key.to_s.upcase }
      @four = "Four"
      @five = "Five"
      @four.stubs(:schema_id).returns("four_id")
      @five.stubs(:schema_id).returns("five_id")
      @set[:four] = @four
      @set[:five] = @five
    end

    it "inherit values from a super-set" do
      @set[:one].must_equal "One"
      @set[:five].must_equal "Five"
    end

    it "test for keys" do
      assert @set.key?(:one)
      assert @set.key?(:five)
    end

    it "test for local keys only" do
      refute @set.key?(:one, false)
      assert @set.key?(:five, false)
    end

    it "enable array-like access by index" do
      @set[3].must_equal "Four"
      @set[0].must_equal "Three"
    end

    it "have a list of names" do
      @set.names.must_equal [:three, :one, :two, :four, :five]
      @set.keys.must_equal [:three, :one, :two, :four, :five]
    end

    it "enable access by schema id" do
      @set.sid("two_id").must_equal @two
      @set.sid("four_id").must_equal @four
    end

    it "have externally settable ordering" do
      @set.order = [:five, :three, :two]
      @set.order.must_equal [:five, :three, :two, :one, :four]
      @set.map { |val| val }.must_equal ['Five', 'Three', 'Two', 'One', 'Four']
      @set.values.must_equal ['Five', 'Three', 'Two', 'One', 'Four']
    end

    it "have a hash-like map function" do
      @set.map { |val| val }.must_equal ["Three", "One", "Two", "Four", "Five"]
    end

    it "have a hash-like each function" do
      keys = []
      @set.each { |val| keys << val }
      keys.must_equal ["Three", "One", "Two", "Four", "Five"]
    end

    it "ignore a nil superobject" do
      set = Spontaneous::Collections::PrototypeSet.new(nil, :prototypes)
      set[:four] = @four
      set[:five] = @five
      set[:four].must_equal @four
      set[:two].must_be_nil
      set.order.must_equal [:four, :five]
    end

    it "have a list of values" do
      @set.values.must_equal ['Three', 'One', 'Two', 'Four', 'Five']
    end

    it "allow access to values as method calls" do
      @set.two.must_equal "Two"
      @set.five.must_equal "Five"
    end

    it "intelligently deal with sub-sets over-writing values" do
      order = @set.order
      @set.first.must_equal "Three"
      @set[:three] = "One Hundred"
      @set[:three].must_equal "One Hundred"
      @set.first.must_equal "One Hundred"
      @set.order.must_equal order
    end

    it "return the last value" do
      @set.last.must_equal "Five"
    end

    it "know the number of entries" do
      @set.length.must_equal 5
      @set.count.must_equal 5
    end

    it "return the first item in the local set" do
      @set.local_first.must_equal "Four"
    end

    it "traverse the object list until it finds a local_first" do
      a = Super.new
      a.prototypes = @set
      set1 = Spontaneous::Collections::PrototypeSet.new(a, :prototypes)
      b = Super.new
      b.prototypes = set1
      set2 = Spontaneous::Collections::PrototypeSet.new(b, :prototypes)
      set1.local_first.must_equal "Four"
      set2.local_first.must_equal "Four"
    end

    it "return nil for local first if empty" do
      a = Super.new
      a.prototypes = Spontaneous::Collections::PrototypeSet.new(nil, :prototypes)
      set1 = Spontaneous::Collections::PrototypeSet.new(a, :prototypes)
      set1.local_first.must_be_nil
    end

    it "correctly search the hierarchy" do
      one = "One"
      one.stubs(:default?).returns(false)
      two = "Two"
      two.stubs(:default?).returns(true)
      three = "Three"
      three.stubs(:default?).returns(false)
      four = "Four"
      four.stubs(:default?).returns(false)
      five = "Five"
      five.stubs(:default?).returns(false)
      six = "Six"
      six.stubs(:default?).returns(true)
      a = Super.new
      a.prototypes = Spontaneous::Collections::PrototypeSet.new(nil, :prototypes)
      a.prototypes[:one] = one
      a.prototypes[:two] = two
      b = Super.new
      b.prototypes = Spontaneous::Collections::PrototypeSet.new(a, :prototypes)
      a.prototypes[:three] = three
      a.prototypes[:four] = four
      c = Super.new
      c.prototypes = Spontaneous::Collections::PrototypeSet.new(b, :prototypes)

      test = proc { |value|
        value.default?
      }

      c.prototypes.hierarchy_detect(&test).must_equal "Two"

      c.prototypes[:five] = five
      c.prototypes[:six] = six

      c.prototypes.hierarchy_detect(&test).must_equal "Six"
    end
  end
end
