# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'eventmachine'

class AsyncTest < MiniTest::Spec

  def setup
    @site = setup_site
    @filename = Time.now.to_i
    @filepath = @site.root / @filename
    File.exist?(@filepath).should be_false
  end

  def teardown
    teardown_site
  end

  context "async system calls" do
    should "be able to test for running EM reactor" do
      Spontaneous.async?.should be_false
      EM.run do
        Spontaneous.async?.should be_true
        EM.stop
      end
      Spontaneous.async?.should be_false
    end

    should "use fibers to simulate sync code if running in a fiber" do
      EM.run do
        Fiber.new {
          result = Spontaneous.system("touch #{@filepath}")
          File.exist?(@filepath).should be_true
        }.resume
        EM.stop
      end
    end

    # TODO: can't get this to work at moment'
    # should "resort to sync code if execution is not running in a fiber" do
    #   EM.run do
    #     result = Spontaneous.system("touch #{@filepath}")
    #     File.exist?(@filepath).should be_true
    #     EM.stop
    #   end
    # end


    should "run synchronously outside of EM reactor" do
      result = Spontaneous.system("touch #{@filepath}")
      File.exist?(@filepath).should be_true
      result.should be_true
    end
  end
end
