# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class HelpersTest < MiniTest::Spec

  def setup
    @site = setup_site
    @site.paths.add :templates, File.expand_path("../../fixtures/helpers/templates", __FILE__)
  end

  def teardown
    teardown_site
  end

  context "Helpers" do
    should "be assignable to a particular format" do
      CustomHelper1 = Site.helper :html do
        def here_is_my_custom_helper1; end
      end

      included_helpers = [
        Spontaneous::Render::ContextBase,
        CustomHelper1,
        Spontaneous::Render::Helpers::ConditionalCommentHelper,
        Spontaneous::Render::Helpers::ClassesHelper,
        Spontaneous::Render::Helpers::ScriptHelper,
        Spontaneous::Render::Helpers::StylesheetHelper
      ]
      helper_module = Site.context :html
      join = included_helpers & helper_module.ancestors
      Set.new(join).should == Set.new(included_helpers)
      helper_module.respond_to?(:here_is_my_custom_helper1).should be_true
    end

    should "be assigned to all formats if none given" do
      CustomHelper2 = Site.helper do
        extend self
        def here_is_my_custom_helper2; end
      end

      assert CustomHelper2.respond_to?(:here_is_my_custom_helper2)

      helper_module = Site.context :html
      helper_module.ancestors.include?(CustomHelper2).should be_true

      helper_module = Site.context :pdf
      helper_module.ancestors.include?(CustomHelper2).should be_true
    end

    should "be available during the render step" do
      class Page < Spontaneous::Page
        add_output :mobile
      end

      CustomHelper3 = Site.helper :html do
        def here_is_my_custom_helper3
          "here_is_my_custom_helper3"
        end
      end

      CustomHelper4 = Site.helper :mobile do
        def here_is_my_custom_helper4
          "here_is_my_custom_helper4"
        end
      end

      page = Page.new
      page.render(:html).should == "<here_is_my_custom_helper3>\n"
      page.render(:mobile).should == "<here_is_my_custom_helper4>\n"
    end
  end

  context "Classes helper" do
    setup do
      @helper = Spontaneous::Render::Helpers::ClassesHelper
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

  context "ConditionalComment helper" do
    setup do
      @helper = Spontaneous::Render::Helpers::ConditionalCommentHelper
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
