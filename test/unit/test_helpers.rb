# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "ContextHelpers" do

  before do
    @site = setup_site
    @site.paths.add :templates, File.expand_path("../../fixtures/helpers/templates", __FILE__)
    @renderer = S::Output::Template::Renderer.new(false)
    S::Output.renderer = @renderer
  end

  after do
    teardown_site
  end

  it "be assignable to a particular format" do
    CustomHelper1 = Site.helper :html do
      def here_is_my_custom_helper1; end
    end

    included_helpers = [
      CustomHelper1,
      Spontaneous::Output::Helpers::ConditionalCommentHelper,
      Spontaneous::Output::Helpers::ClassesHelper,
      Spontaneous::Output::Helpers::ScriptHelper,
      Spontaneous::Output::Helpers::StylesheetHelper
    ]
    helper_module = Site.context :html
    join = included_helpers & helper_module.ancestors
    Set.new(join).must_equal Set.new(included_helpers)
    assert helper_module.respond_to?(:here_is_my_custom_helper1)
  end

  it "be assigned to all formats if none given" do
    CustomHelper2 = Site.helper do
      extend self
      def here_is_my_custom_helper2; end
    end

    assert CustomHelper2.respond_to?(:here_is_my_custom_helper2)

    helper_module = Site.context :html
    assert helper_module.ancestors.include?(CustomHelper2)

    helper_module = Site.context :pdf
    assert helper_module.ancestors.include?(CustomHelper2)
  end

  it "be available during the render step" do
    class Page < Content::Page
      add_output :mobile
    end

    Site.helper :html do
      def here_is_my_custom_helper3
        "here_is_my_custom_helper3"
      end
      extend self
    end

    Site.helper :mobile do
      def here_is_my_custom_helper4
        "here_is_my_custom_helper4"
      end
      extend self
    end

    page = Page.new
    page.render(:html).must_equal "<here_is_my_custom_helper3>\n"
    page.render(:mobile).must_equal "<here_is_my_custom_helper4>\n"
  end

  describe "Classes helper" do
    before do
      @helper = Spontaneous::Output::Helpers::ClassesHelper
    end
    it "enable easy addition of classes" do
      classes = @helper.classes("a", "b", "c", :active => false, :invisible => true)
      classes.must_equal %(class="a b c invisible")

      classes = @helper.classes("a", "b", "c")
      classes.must_equal %(class="a b c")

      classes = @helper.classes(%w(a b c))
      classes.must_equal %(class="a b c")

      classes = @helper.classes(%w(a b c), "active" => false, "invisible" => true)
      classes.must_equal %(class="a b c invisible")


      classes = @helper.classes("a b c")
      classes.must_equal %(class="a b c")

      classes = @helper.classes("a b c", :active => false, :invisible => true)
      classes.must_equal %(class="a b c invisible")
    end
  end

  describe "ConditionalComment helper" do
    before do
      @helper = Spontaneous::Output::Helpers::ConditionalCommentHelper
    end

    it "provide a wrapper around IE conditional comments" do
      @helper.ie_only.must_equal "<!--[if IE]>"
      @helper.ie_only(6).must_equal "<!--[if IE 6]>"
      @helper.ie_only(7).must_equal "<!--[if IE 7]>"
      @helper.ie_only_gt(7).must_equal "<!--[if gt IE 7]>"
      @helper.ie_only_gte(7).must_equal "<!--[if gte IE 7]>"
      @helper.ie_only_gte(8).must_equal "<!--[if gte IE 8]>"
      @helper.ie_only_lt(7).must_equal "<!--[if lt IE 7]>"
      @helper.ie_only_lte(9).must_equal "<!--[if lte IE 9]>"
      @helper.ie_only_end.must_equal "<![endif]-->"
    end

    it "enable targeting a range of ie versions using ranges" do
      @helper.ie_only(6..8).must_equal "<!--[if (gte IE 6)&(lte IE 8)]>"
      @helper.ie_only(6...8).must_equal "<!--[if (gte IE 6)&(lte IE 7)]>"
    end

    it "provide a wrapper around only comments excluding IE" do
      @helper.not_ie.must_equal "<!--[if !IE]> -->"
      @helper.not_ie_end.must_equal "<!-- <![endif]-->"
    end
  end
end
