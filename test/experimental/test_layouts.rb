# encoding: UTF-8

require 'test_helper'

class LayoutsTest < MiniTest::Spec

  context "layouts" do

    setup do
      Spontaneous.template_root = ::File.expand_path('../../fixtures/layouts', __FILE__)
      class ::HomePage < Spontaneous::Page; end
      class ::ABoxClass < Spontaneous::Box; end
      class ::SubPage < HomePage; end
      ABoxClass.style :monkey
      ABoxClass.style :crazy

      class ::SomeContent < Spontaneous::Piece; end
    end

    teardown do
      [:HomePage, :SubPage, :ABoxClass, :SomeContent].each do |c|
        Object.send(:remove_const, c) rescue nil
      end
    end

    context "Page layouts" do
      setup do
      end
      should "default to layouts/standard.html... if nothing defined" do
        page = HomePage.new
        page.layout.template.should == 'layouts/standard'
        page.render.should == "layouts/standard.html.cut\n"
      end

      should "return the first layout if some are declared but none declared default" do
        HomePage.layout :custom1
        HomePage.layout :custom2
        page = HomePage.new
        page.layout.template.should == 'layouts/custom1'
        page.render.should == "layouts/custom1.html.cut\n"
      end
      should "return the layout declared default" do
        HomePage.layout :custom1
        HomePage.layout :custom2, :default => true
        page = HomePage.new
        page.layout.template.should == 'layouts/custom2'
        page.render.should == "layouts/custom2.html.cut\n"
      end

      should "inherit templates from superclass" do
        HomePage.layout :custom1
        HomePage.layout :custom2, :default => true
        page = SubPage.new
        page.layout.template.should == 'layouts/custom2'
      end
      should "be able to overwrite inherited templates from superclass" do
        HomePage.layout :custom1
        HomePage.layout :custom2, :default => true
        SubPage.layout :custom3
        page = SubPage.new
        page.layout.template.should == 'layouts/custom3'
      end

      should "allow setting of style used" do
        HomePage.layout :custom1
        HomePage.layout :custom2
        page = HomePage.new
        page.layout.template.should == 'layouts/custom1'
        page.layout = :custom2
        page.layout.template.should == 'layouts/custom2'
      end

      should "allow setting of layout in sub-classes" do
        HomePage.layout :custom1
        HomePage.layout :custom2
        SubPage.layout :custom3
        page = SubPage.new
        page.layout.template.should == 'layouts/custom3'
        page.layout = :custom2
        page.layout.template.should == 'layouts/custom2'
      end
      should "raise error when setting unknown layout" do
        HomePage.layout :custom1
        HomePage.layout :custom2
        SubPage.layout :custom3
        page = SubPage.new
        lambda { page.layout = :wrong }.must_raise(Spontaneous::Errors::UnknownLayoutError)
      end
    end
  end
end
