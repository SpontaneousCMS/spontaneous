# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

$suite1_start = $suite2_start = $suite3_start = nil

describe "Suite1" do
  start do
    $suite1_start = true
  end

  finish do
    $suite1_start = false
  end

  it "1" do
    assert $suite1_start
  end

  describe "a" do
    it "1" do
      assert $suite1_start
    end

    it "2" do
      assert true
    end

    describe "a" do
      it "1" do
        assert true
      end

      it "2" do
        assert $suite1_start
        $suite2_start.must_be_nil
      end
    end
  end
end

describe "Suite2a" do
  it "a" do
    assert $suite1_start == false
  end
end

describe "Suite2b" do
  start do
    $suite2_start = true
  end

  finish do
    $suite2_start = false
  end

  it "a" do
    assert $suite1_start == false
    assert $suite2_start
    $suite3_start.must_be_nil
  end
end

describe "Suite3" do
  start do
    $suite3_start = true
  end

  finish do
    $suite3_start = false
  end

  it "1" do
    assert $suite1_start == false
    assert $suite2_start == false
    assert $suite3_start
  end

  describe "a" do
    it "1" do
      assert $suite1_start == false
      assert $suite2_start == false
      assert $suite3_start
    end

    describe "a" do
      it "2" do
        assert $suite3_start
      end
    end
  end
  describe "a" do
    it "2" do
      assert $suite3_start
    end
  end
end

MiniTest::Unit.after_tests do
  if $suite3_start
    raise "$suite3_start should be false but is #{$suite3_start.inspect}"
  end
end
