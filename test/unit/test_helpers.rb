# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class HelpersTest < MiniTest::Spec

  context "HTML helper" do
    setup do
      @helper = Spontaneous::Render::Helpers::HTMLHelper
    end
    should "enable easy addition of classes" do
      classes = @helper.classes("a", "b", "c", :active => false, :invisible => true)
      classes.should == %(class="a b c invisible")

      classes = @helper.classes("a", "b", "c")
      classes.should == %(class="a b c")

      classes = @helper.classes(%w(a b c))
      classes.should == %(class="a b c")

      classes = @helper.classes(%w(a b c), "active" => false, "invisible" => true)
      classes.should == %(class="a b c invisible")


      classes = @helper.classes("a b c")
      classes.should == %(class="a b c")

      classes = @helper.classes("a b c", :active => false, :invisible => true)
      classes.should == %(class="a b c invisible")
    end
  end
end
