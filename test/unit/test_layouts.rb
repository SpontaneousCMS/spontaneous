# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class LayoutsTest < MiniTest::Spec

  def setup
    Spontaneous::Render.use_development_renderer
    self.template_root = ::File.expand_path('../../fixtures/layouts', __FILE__)
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "layouts" do

    setup do
      class ::LayoutPage < Spontaneous::Page; end
      class ::ABoxClass < Spontaneous::Box; end
      class ::SubPage < LayoutPage; end
      ABoxClass.style :monkey
      ABoxClass.style :crazy

      class ::SomeContent < Spontaneous::Piece; end
    end

    teardown do
      [:LayoutPage, :SubPage, :ABoxClass, :SomeContent].each do |c|
        Object.send(:remove_const, c) rescue nil
      end
    end

    context "Page layouts" do
      setup do
      end
      should "default to layouts/standard.html... if nothing defined" do
        page = LayoutPage.new
        assert_correct_template(page, 'layouts/standard')
        page.render.should == "layouts/standard.html.cut\n"
      end

      should "return the first layout if some are declared but none declared default" do
        LayoutPage.layout :custom1
        LayoutPage.layout :custom2
        page = LayoutPage.new
        assert_correct_template(page, 'layouts/custom1')
        page.render.should == "layouts/custom1.html.cut\n"
      end
      should "return the layout declared default" do
        LayoutPage.layout :custom1
        LayoutPage.layout :custom2, :default => true
        page = LayoutPage.new
        assert_correct_template(page, 'layouts/custom2')
        page.render.should == "layouts/custom2.html.cut\n"
      end

      should "inherit templates from superclass" do
        LayoutPage.layout :custom1
        LayoutPage.layout :custom2, :default => true
        page = SubPage.new
        assert_correct_template(page, 'layouts/custom2')
      end

      should "be able to overwrite inherited templates from superclass" do
        LayoutPage.layout :custom1
        LayoutPage.layout :custom2, :default => true
        SubPage.layout :custom3
        page = SubPage.new
        # page.layout.template.should == 'layouts/custom2'
        assert_correct_template(page, 'layouts/custom2')
      end

      should "allow setting of style used" do
        LayoutPage.layout :custom1
        LayoutPage.layout :custom2
        page = LayoutPage.new
        assert_correct_template(page, 'layouts/custom1')
        # page.layout.template.should == 'layouts/custom1'
        page.layout = :custom2
        assert_correct_template(page, 'layouts/custom2')
        # page.layout.template.should == 'layouts/custom2'
      end

      should "allow setting of layout in sub-classes" do
        LayoutPage.layout :custom1
        LayoutPage.layout :custom2
        SubPage.layout :custom3, :default => true
        page = SubPage.new
        assert_correct_template(page, 'layouts/custom3')
        page.layout = :custom2
        assert_correct_template(page, 'layouts/custom2')
      end
      # should "raise error when setting unknown layout" do
      #   LayoutPage.layout :custom1
      #   LayoutPage.layout :custom2
      #   SubPage.layout :custom3
      #   page = SubPage.new
      #   lambda { page.layout = :wrong }.must_raise(Spontaneous::Errors::UnknownLayoutError)
      # end
      # should "have a list of formats" do
      #   LayoutPage.layout :custom1
      #   skip("Need to implement formats correctly")
      # end

      # should "be able to test that an instance supports a format" do
      #   skip("Need to implement formats correctly")
      #   LayoutPage.layout :custom1
      #   page = LayoutPage.new
      #   # page.provides_format?(:html).should be_true
      # end
    end
  end
end
