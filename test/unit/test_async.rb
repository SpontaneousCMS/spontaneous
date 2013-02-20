# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'eventmachine'

describe "Async" do

  before do
    @site = setup_site
    @filename = Time.now.to_i
    @filepath = @site.root / @filename
    refute File.exist?(@filepath)
  end

  after do
    teardown_site
  end

  it "be able to test for running EM reactor" do
    refute Spontaneous.async?
    EM.run do
      assert Spontaneous.async?
      EM.stop
    end
    refute Spontaneous.async?
  end

  it "run synchronously outside of EM reactor" do
    Spontaneous.system("touch #{@filepath}") { |result|
      assert File.exist?(@filepath)
      assert result

    }
  end
end
