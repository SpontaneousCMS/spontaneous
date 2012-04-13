# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class FormatsTest < MiniTest::Spec
  context "Pages" do
    setup do
      @site = setup_site
      @site.paths.add :templates, File.expand_path('../../fixtures/outputs/templates', __FILE__)
      class Page < Spontaneous::Page; end
      class FPage < Page; end
    end

    teardown do
      self.class.send(:remove_const, :Page) rescue nil
      self.class.send(:remove_const, :FPage) rescue nil
      teardown_site
    end

    context "default output" do
      should "be named :html" do
        FPage.outputs.map(&:name).should == [:html]
      end

      should "be html format" do
        FPage.outputs.map(&:format).should == [:html]
      end

      should "be public" do
        FPage.outputs.map(&:private?).should == [false]
        FPage.outputs.map(&:public?).should ==  [true]
      end

      should "be static" do
        FPage.outputs.map(&:dynamic?).should == [false]
      end
    end

    should "have tests for supported outputs" do
      FPage.provides_output?(:html).should be_true
      FPage.provides_output?(:rss).should be_false
    end

    should "map an empty output onto the default one" do
      FPage.provides_output?(nil).should be_true
    end

    should "return the mime-type for a output" do
      FPage.mime_type(:html).should == "text/html"
      FPage.mime_type(:atom).should == "application/atom+xml"
    end


    should "return the output class for a named output" do
      FPage.output(:html).must_be_instance_of(Class)
      FPage.output(:html).ancestors.include?(S::Render::Output::HTML).should be_true
    end

    should "correctly determine mimetypes for new (known) formats" do
      FPage.add_output :au
      FPage.output(:au).mimetype.should == "audio/basic"
    end

    should "dynamically generate output classes for unknown formats" do
      FPage.add_output :fish, :format => :unknown
      FPage.output(:fish).ancestors[1].should == S::Render::Output::UNKNOWN
      FPage.output(:fish).ancestors[2].should == S::Render::Output::Plain
    end

    should "dynamically generate output classes based on HTML for outputs with unspecified formats" do
      FPage.add_output :fish
      FPage.output(:fish).ancestors[1].should == S::Render::Output::HTML
    end

    should "return the format wrapper for a format name string" do
      FPage.output("html").should == FPage.output(:html)
    end

    should "give the default format for blank format names" do
      html = FPage.output(:html)
      FPage.output(nil).should == html
      FPage.output.should == html
    end

    should "provide a symbol version of the output name" do
      FPage.output(:html).to_sym.should == :html
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

    should "correctly set the format from the output name if it's recognised" do
      FPage.add_output :pdf
      FPage.output(:pdf).format.should == :pdf
      FPage.output(:pdf).mimetype.should == "application/pdf"
    end

    should "default to a format of html for unknown output formats" do
      FPage.outputs [:xyzz]
      FPage.default_output.format.should == :html
      FPage.output(:xyzz).format.should == :html
      FPage.output(:xyzz).mimetype.should == "text/html"
    end

    should "allow the setting of a default format for an output" do
      FPage.add_output :rss, :format => :html
      FPage.output(:rss).format.should == :html
      FPage.output(:rss).mimetype.should == "text/html"
    end

    should "allow for custom mimetypes" do
      FPage.add_output :rss, :format => :html, :mimetype => "application/xhtml+xml"
      FPage.output(:rss).format.should == :html
      FPage.output(:rss).mimetype.should == "application/xhtml+xml"
    end

    should "allow for marking an output as 'private'" do
      FPage.add_output :rss, :private => true
      FPage.output(:rss).public?.should be_false
      FPage.output(:rss).private?.should be_true
    end

    should "provide the correct output extension for static pages" do
      FPage.output(:html).extension.should == ".html"
    end

    should "provide the correct output extension for static pages" do
      FPage.add_output :pdf
      FPage.output(:pdf).extension.should == ".pdf"
    end

    should "name the output according to the format" do
      FPage.add_output :atom, :format => :html
      FPage.output(:atom).extension.should == ".atom"
    end

    should "name the output using the configured extension" do
      FPage.add_output :atom, :format => :html, :extension => "rss"
      FPage.output(:atom).extension.should == ".rss"
    end

    should "allow for complex custom file extensions" do
      FPage.add_output :rss, :extension => ".rss.xml.php"
      FPage.output(:rss).extension.should == ".rss.xml.php"
      FPage.output(:rss).extension(true).should == ".rss.xml.php"
    end

    # not sure I need this. The dynamic? flag is either set to always true in the output defn
    # in which case you can use the :extension setting to just absolutely set the final output
    # extension, or the rendered page is detected as dynamic by the templating system in which
    # case it's most likely that the output language is the same as the templating system.
    should "allow for setting a custom dynamic extension" do
      FPage.add_output :fish, :format => :html, :dynamic => true, :language => "php"
      FPage.output(:fish).extension.should == ".fish.php"
      FPage.add_output :foul, :format => :html, :language => "php"
      FPage.output(:foul).extension(true).should == ".foul.php"
    end

    # What would be more useful perhaps is a way to define a custom, per output, test for "dynamicness"
    should "allow for a custom test for dynamicness"

    should "override extension even for dynamic outputs" do
      FPage.add_output :fish, :dynamic => true, :extension => "php"
      FPage.output(:fish).extension(true).should == ".php"
      FPage.add_output :foul, :dynamic => true, :extension => ".php"
      FPage.output(:foul).extension(true).should == ".php"
    end

    context "format classes" do
      should "enable new formats" do
        S::Render::Output.unknown_format?(:fishhtml).should be_true
        class FishHTMLFormat < S::Render::Output::HTML
          provides_format :fishhtml
        end
        S::Render::Output.unknown_format?(:fishhtml).should be_false
      end

      should "inherit helper classes from their superclass" do
        module CustomHelper1
          def here_is_my_custom_helper1; end
        end
        Site.register_helper CustomHelper1, :newhtml

        class NewHTMLFormat < S::Render::Output::HTML
          provides_format :newhtml
        end

        FPage.add_output :newhtml
        page = FPage.new
        output = page.output(:newhtml)
        newhtml_context = output.context
        html_context_ancestors = page.output(:html).context.ancestors[1..-1]
        Set.new(newhtml_context.ancestors[1..-1]).should == Set.new(html_context_ancestors + [CustomHelper1])
      end
    end

    context "instances" do
      setup do
        FPage.add_output :pdf, :dynamic => true
        @page = FPage.new
      end

      should "generate a list of output instances tied to the page" do
        outputs = @page.outputs
        outputs.map(&:class).should == [FPage.output(:html), FPage.output(:pdf)]
      end

      should "generate output instances tied to the page" do
        @page.outputs.map(&:format).should == [:html, :pdf]
        @page.default_output.format.should == :html

        output = @page.output(:html)
        output.must_be_instance_of FPage.output(:html)
        output.page.should == @page
        output.format.should == :html
        output.dynamic?.should be_false
        output.extension.should == ".html"

        @page.output(:pdf).dynamic?.should be_true
      end

      should "provide a default output instance" do
        output = @page.default_output
        output.must_be_instance_of FPage.output(:html)
      end

      should "know that they provide a certain format" do
        @page.provides_output?(:html).should be_true
        @page.provides_output?(:pdf).should be_true
        @page.provides_output?(:xyz).should be_false
      end

      should "provide a symbol version of the output name" do
        @page.output(:html).to_sym.should == :html
      end

      should "return the output instance if used as an output request" do
        output = @page.output(:html)
        @page.output(output).should == output
      end
    end

    context "with custom formats" do
      setup do
        FPage.outputs :rss, :html, :json
      end

      should "be able to define their supported formats" do
        FPage.outputs.map(&:format).should == [:rss, :html, :json]
      end

      should "re-define the default format" do
        FPage.default_output.format.should == :rss
      end

      should "have tests for supported formats" do
        FPage.provides_output?(:html).should be_true
        FPage.provides_output?(:rss).should be_true
        FPage.provides_output?(:json).should be_true
        FPage.provides_output?(:xyz).should be_false
      end


      should "accept new formats when accompanied by a mime-type" do
        FPage.outputs [:xyz, {:mimetype => "application/xyz"}]
      end

      should "allow addition of a single format" do
        FPage.add_output :atom
        FPage.outputs.map(&:format).should == [:rss, :html, :json, :atom]
      end

      should "allow custom post-processing of render" do
        FPage.add_output :atom, :postprocess => lambda { |page, output| output.gsub(/a/, 'x') }
        page = FPage.new
        page.render(:atom).should =~ /<xtom>/
      end
    end

    context "with custom mime-types" do
      setup do
        FPage.outputs [ :html, {:mimetype => "application/xhtml+xml"}], [:js, {:mimetype => "application/json"} ]
      end

      should "still provide the correct default format" do
        FPage.default_output.format.should == :html
        FPage.default_output.name.should == :html
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
        FPage.add_output :ddd, :mimetype => "application/ddd"
        FPage.outputs.map(&:format).should == [:html, :js, :ddd]
        page = FPage.new
        page.mime_type(:ddd).should == "application/ddd"
      end
    end

    context "with subclasses" do
      setup do
        FPage.outputs :html, :rss, [:xxx, { :mimetype => "application/xxx" }]
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
        FPage.add_output :mako, :mimetype => "application/x-mako", :dynamic => true
        FPage.output(:mako).mime_type.should == "application/x-mako"
        FPage.output(:mako).dynamic?.should be_true
      end

      should "be able to override the default dynamic extension" do
        FPage.add_output :html, :dynamic => true, :language => "mako"
        FPage.add_output :alternate, :mimetype => "text/html", :dynamic => true, :language => "mako"
        FPage.output(:html).dynamic?.should be_true
        FPage.output(:html).extension.should == ".html.mako"
        FPage.output(:alternate).extension.should == ".alternate.mako"
      end
    end
  end
end
