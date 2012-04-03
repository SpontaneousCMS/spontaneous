# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class FormatsTest < MiniTest::Spec
  context "Pages" do
    setup do
      @site = setup_site
      class Page < Spontaneous::Page; end
      class FPage < Page; end
    end

    teardown do
      self.class.send(:remove_const, :Page) rescue nil
      self.class.send(:remove_const, :FPage) rescue nil
      teardown_site
    end

    should "default to a single :html format" do
      FPage.formats.should == [:html]
    end

    should "have a default format of :html" do
      FPage.default_format.should == :html
    end

    should "have tests for supported formats" do
      FPage.provides_format?(:html).should be_true
      FPage.provides_format?(:rss).should be_false
    end

    should "return the mime-type for a format" do
      FPage.mime_type(:html).should == "text/html"
      FPage.mime_type(:atom).should == "application/atom+xml"
    end

    should "default to static output" do
      FPage.format(:html).dynamic?.should be_false
    end

    should "return the format wrapper for a format name" do
      FPage.format(FPage.format(:html)).format.should == :html
    end
    should "return the format wrapper for a format name string" do
      FPage.format("html").should == :html
    end

    should "give the default format for blank format names" do
      FPage.format(nil).format.should == :html
      FPage.format.format.should == :html
      FPage.format.should == :html
      FPage.format.ext.should == ".html"
    end

    context "instances" do
      setup do
        @page = FPage.new
      end
      should "pass on their formats to instances" do
        @page.formats.should == [:html]
        @page.default_format.should == :html
        @page.provides_format?(:html).should be_true
      end
    end

    context "with custom formats" do
      setup do
        FPage.formats :rss, :html, :json
      end

      should "be able to define their supported formats" do
        FPage.formats.should == [:rss, :html, :json]
      end

      should "re-define the default format" do
        FPage.default_format.should == :rss
      end

      should "have tests for supported formats" do
        FPage.provides_format?(:html).should be_true
        FPage.provides_format?(:rss).should be_true
        FPage.provides_format?(:json).should be_true
        FPage.provides_format?(:xyz).should be_false
      end

      should "raise an error if trying to use an unknown format without specifying a mime-type" do
        lambda { FPage.formats [:xyzz] }.must_raise(Spontaneous::UnknownFormatException)
      end

      should "accept new formats when accompanied by a mime-type" do
        FPage.formats [{:xyz => "application/xyz"}]
      end

      should "allow addition of a single format" do
        FPage.add_format :atom
        FPage.formats.should == [:rss, :html, :json, :atom]
      end
    end

    context "with custom mime-types" do
      setup do
        FPage.formats [ {:html => "application/xhtml+xml"}, {:js => "application/json"} ]
      end

      should "still provide the correct default format" do
        FPage.default_format.should == :html
      end

      should "return the custom mime-type for a format" do
        FPage.mime_type(:html).should == "application/xhtml+xml"
        FPage.mime_type(:js).should == "application/json"
        FPage.mime_type(:atom).should == "application/atom+xml"
      end

      should "return mime-type values from instances" do
        page = FPage.new
        page.mime_type(:html).should == "application/xhtml+xml"
      end

      should "allow addition of a single custom format" do
        FPage.add_format :ddd => "application/ddd"
        FPage.formats.should == [:html, :js, :ddd]
        page = FPage.new
        page.mime_type(:ddd).should == "application/ddd"
      end
    end

    context "with subclasses" do
      setup do
        FPage.formats :html, :rss, { :xxx => "application/xxx" }
        class FSubPage < FPage
        end
      end

      teardown do
        self.class.send(:remove_const, :FSubPage) rescue nil
      end

      should "inherit the list of provided formats" do
        FSubPage.formats.should == FPage.formats
      end
      should "inherit any custom mimetypes" do
        FPage.mime_type(:xxx).should == "application/xxx"
        FSubPage.mime_type(:xxx).should == "application/xxx"
      end
    end

    context "that generate dynamic outputs" do
      should "be able to specify that a format is always dynamic" do
        FPage.add_format :rss, :dynamic => true
        FPage.format(:rss).dynamic?.should be_true
      end

      should "be able to specify that a format with custom mimetype is always dynamic" do
        FPage.add_format :mako => "application/x-mako", :dynamic => true
        FPage.format(:mako).mime_type.should == "application/x-mako"
        FPage.format(:mako).dynamic?.should be_true
      end
    end
  end
end
