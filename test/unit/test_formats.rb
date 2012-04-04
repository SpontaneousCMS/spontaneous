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
      FPage.outputs.should == [:html]
    end

    should "have a default output of :html" do
      FPage.default_output.should == :html
    end

    should "have tests for supported outputs" do
      FPage.provides_format?(:html).should be_true
      FPage.provides_format?(:rss).should be_false
    end

    should "return the mime-type for a output" do
      FPage.mime_type(:html).should == "text/html"
      FPage.mime_type(:atom).should == "application/atom+xml"
    end

    should "default to static output" do
      FPage.output(:html).dynamic?.should be_false
    end

    should "return the format wrapper for a format name" do
      FPage.output(FPage.output(:html)).format.should == :html
    end
    should "return the format wrapper for a format name string" do
      FPage.output("html").should == :html
    end

    should "give the default format for blank format names" do
      FPage.output(nil).format.should == :html
      FPage.output.format.should == :html
      FPage.output.should == :html
    end

    should "provide the correct output extension for static pages" do
      FPage.output.extension.should == ".html"
    end

    should "provide the correct output extension for dynamic pages" do
      FPage.output.extension(true).should == ".html.cut"
      FPage.output.extension(true, "erb").should == ".html.erb"
    end

    should "override an existing output if the format is the same" do
      FPage.add_output :rss
      FPage.outputs.length.should == 2
      FPage.outputs.map(&:format).should == [:html, :rss]
      format = FPage.outputs.first.format
      FPage.add_output format, :dynamic => true
      FPage.outputs.length.should == 2
      FPage.outputs.map(&:format).should == [:html, :rss]
      FPage.output(format).dynamic?.should be_true
    end

    context "instances" do
      setup do
        @page = FPage.new
      end
      should "pass on their formats to instances" do
        @page.outputs.should == [:html]
        @page.default_output.should == :html
        @page.provides_format?(:html).should be_true
      end
    end

    context "with custom formats" do
      setup do
        FPage.outputs :rss, :html, :json
      end

      should "be able to define their supported formats" do
        FPage.outputs.should == [:rss, :html, :json]
      end

      should "re-define the default format" do
        FPage.default_output.should == :rss
      end

      should "have tests for supported formats" do
        FPage.provides_format?(:html).should be_true
        FPage.provides_format?(:rss).should be_true
        FPage.provides_format?(:json).should be_true
        FPage.provides_format?(:xyz).should be_false
      end

      should "raise an error if trying to use an unknown format without specifying a mime-type" do
        lambda { FPage.outputs [:xyzz] }.must_raise(Spontaneous::UnknownFormatException)
      end

      should "accept new formats when accompanied by a mime-type" do
        FPage.outputs [{:xyz => "application/xyz"}]
      end

      should "allow addition of a single format" do
        FPage.add_output :atom
        FPage.outputs.should == [:rss, :html, :json, :atom]
      end
    end

    context "with custom mime-types" do
      setup do
        FPage.outputs [ {:html => "application/xhtml+xml"}, {:js => "application/json"} ]
      end

      should "still provide the correct default format" do
        FPage.default_output.should == :html
      end

      should "return the custom mime-type for a output" do
        FPage.mime_type(:html).should == "application/xhtml+xml"
        FPage.mime_type(:js).should == "application/json"
        FPage.mime_type(:atom).should == "application/atom+xml"
      end

      should "return mime-type values from instances" do
        page = FPage.new
        page.mime_type(:html).should == "application/xhtml+xml"
      end

      should "allow addition of a single custom output" do
        FPage.add_output :ddd => "application/ddd"
        FPage.outputs.should == [:html, :js, :ddd]
        page = FPage.new
        page.mime_type(:ddd).should == "application/ddd"
      end
    end

    context "with subclasses" do
      setup do
        FPage.outputs :html, :rss, { :xxx => "application/xxx" }
        class FSubPage < FPage
        end
      end

      teardown do
        self.class.send(:remove_const, :FSubPage) rescue nil
      end

      should "inherit the list of provided outputs" do
        FSubPage.outputs.should == FPage.outputs
      end
      should "inherit any custom mimetypes" do
        FPage.mime_type(:xxx).should == "application/xxx"
        FSubPage.mime_type(:xxx).should == "application/xxx"
      end
    end

    context "that generate dynamic outputs" do
      should "be able to specify that a output is always dynamic" do
        FPage.add_output :rss, :dynamic => true
        FPage.output(:rss).dynamic?.should be_true
      end

      should "be able to specify that a output with custom mimetype is always dynamic" do
        FPage.add_output :mako => "application/x-mako", :dynamic => true
        FPage.output(:mako).mime_type.should == "application/x-mako"
        FPage.output(:mako).dynamic?.should be_true
      end

      should "be able to override the default dynamic extension" do
        FPage.add_output :html, :dynamic => true, :extension => "mako"
        FPage.add_output :alternate => "text/html", :dynamic => true, :extension => "mako"
        FPage.output(:html).dynamic?.should be_true
        FPage.output(:html).extension.should == ".html.mako"
        FPage.output(:alternate).extension.should == ".alternate.mako"
      end
    end
  end
end
