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

    should "provide a wrapper around IE conditional comments" do
      @helper.ie_only.should == "<!--[if IE]>"
      @helper.ie_only(6).should == "<!--[if IE 6]>"
      @helper.ie_only(7).should == "<!--[if IE 7]>"
      @helper.ie_only_gt(7).should == "<!--[if gt IE 7]>"
      @helper.ie_only_gte(7).should == "<!--[if gte IE 7]>"
      @helper.ie_only_gte(8).should == "<!--[if gte IE 8]>"
      @helper.ie_only_lt(7).should == "<!--[if lt IE 7]>"
      @helper.ie_only_lte(9).should == "<!--[if lte IE 9]>"
      @helper.ie_only_end.should == "<![endif]-->"
    end

    should "enable targeting a range of ie versions using ranges" do
      @helper.ie_only(6..8).should == "<!--[if (gte IE 6)&(lte IE 8)]>"
      @helper.ie_only(6...8).should == "<!--[if (gte IE 6)&(lte IE 7)]>"
    end

    should "provide a wrapper around only comments excluding IE" do
      @helper.not_ie.should == "<!--[if !IE]> -->"
      @helper.not_ie_end.should == "<!-- <![endif]-->"
    end
  end
end
