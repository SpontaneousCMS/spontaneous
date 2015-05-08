# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Outputs" do
  before do
    @site = setup_site
    @site.paths.add :templates, File.expand_path('../../fixtures/outputs/templates', __FILE__)
  end

  after do
    teardown_site
  end

  describe "Pages" do
    before do
      class FPage < ::Page; end
    end

    after do
      Object.send(:remove_const, :FPage) rescue nil
    end

    describe "default output" do
      it "be named :html" do
        FPage.outputs.map(&:name).must_equal [:html]
      end

      it "be html format" do
        FPage.outputs.map(&:format).must_equal [:html]
      end

      it "be public" do
        FPage.outputs.map(&:private?).must_equal [false]
        FPage.outputs.map(&:public?).must_equal  [true]
      end

      it "be static" do
        FPage.outputs.map(&:dynamic?).must_equal [false]
      end
    end

    it "have tests for supported outputs" do
      assert FPage.provides_output?(:html)
      refute FPage.provides_output?(:rss)
    end

    it "map an empty output onto the default one" do
      assert FPage.provides_output?(nil)
    end

    it "return the mime-type for a output" do
      FPage.mime_type(:html).must_equal "text/html"
      FPage.mime_type(:atom).must_equal "application/atom+xml"
    end


    it "return the output class for a named output" do
      FPage.output(:html).must_be_instance_of(Class)
      assert FPage.output(:html).ancestors.include?(S::Output::HTML)
    end

    it "correctly determine mimetypes for new (known) formats" do
      FPage.add_output :au
      FPage.output(:au).mimetype.must_equal "audio/basic"
    end

    it "dynamically generate output classes for unknown formats" do
      FPage.add_output :fish, :format => :unknown
      FPage.output(:fish).ancestors[1].must_equal S::Output::UNKNOWN
      FPage.output(:fish).ancestors[2].must_equal S::Output::Plain
    end

    it "dynamically generate output classes based on HTML for outputs with unspecified formats" do
      FPage.add_output :fish
      FPage.output(:fish).ancestors[1].must_equal S::Output::HTML
    end

    it "return the format wrapper for a format name string" do
      FPage.output("html").must_equal FPage.output(:html)
    end

    it "give the default format for blank format names" do
      html = FPage.output(:html)
      FPage.output(nil).must_equal html
      FPage.output.must_equal html
    end

    it "provide a symbol version of the output name" do
      FPage.output(:html).to_sym.must_equal :html
    end

    it "provide the correct output extension for dynamic pages" do
      FPage.output.extension(true).must_equal ".html.cut"
      FPage.output.extension(true, "erb").must_equal ".html.erb"
    end

    it "override an existing output if the format is the same" do
      FPage.add_output :rss
      FPage.outputs.length.must_equal 2
      FPage.outputs.map(&:format).must_equal [:html, :rss]
      format = FPage.outputs.first.format
      FPage.add_output format, :dynamic => true
      FPage.outputs.length.must_equal 2
      FPage.outputs.map(&:format).must_equal [:html, :rss]
      assert FPage.output(format).dynamic?
    end

    it "correctly set the format from the output name if it's recognised" do
      FPage.add_output :pdf
      FPage.output(:pdf).format.must_equal :pdf
      FPage.output(:pdf).mimetype.must_equal "application/pdf"
    end

    it "default to a format of html for unknown output formats" do
      FPage.outputs [:xyzz]
      FPage.default_output.format.must_equal :html
      FPage.output(:xyzz).format.must_equal :html
      FPage.output(:xyzz).mimetype.must_equal "text/html"
    end

    it "allow the setting of a default format for an output" do
      FPage.add_output :rss, :format => :html
      FPage.output(:rss).format.must_equal :html
      FPage.output(:rss).mimetype.must_equal "text/html"
    end

    it "allow for custom mimetypes" do
      FPage.add_output :rss, :format => :html, :mimetype => "application/xhtml+xml"
      FPage.output(:rss).format.must_equal :html
      FPage.output(:rss).mimetype.must_equal "application/xhtml+xml"
    end

    it "knows if the configured mimetype is different from that inferred from the extension" do
      output = FPage.add_output :html, :format => :html, :mimetype => "text/html"
      output.custom_mimetype?.must_equal false
      output = FPage.add_output :rss
      output.custom_mimetype?.must_equal false
      output = FPage.add_output :rss, :format => :html, :mimetype => "application/xhtml+xml"
      output.custom_mimetype?.must_equal true
    end

    it "allow for marking an output as 'private'" do
      FPage.add_output :rss, :private => true
      refute FPage.output(:rss).public?
      assert FPage.output(:rss).private?
    end

    it "provide the correct output extension for static pages" do
      FPage.output(:html).extension.must_equal ".html"
    end

    it "provide the correct output extension for static pages of non-html formats" do
      FPage.add_output :pdf
      FPage.output(:pdf).extension.must_equal ".pdf"
    end

    it "name the output according to the format" do
      FPage.add_output :atom, :format => :html
      FPage.output(:atom).extension.must_equal ".atom"
    end

    it "name the output using the configured extension" do
      FPage.add_output :atom, :format => :html, :extension => "rss"
      FPage.output(:atom).extension.must_equal ".rss"
    end

    it "allow for complex custom file extensions" do
      FPage.add_output :rss, :extension => ".rss.xml.php"
      FPage.output(:rss).extension.must_equal ".rss.xml.php"
      FPage.output(:rss).extension(true).must_equal ".rss.xml.php"
    end

    # not sure I need this. The dynamic? flag is either set to always true in the output defn
    # in which case you can use the :extension setting to just absolutely set the final output
    # extension, or the rendered page is detected as dynamic by the templating system in which
    # case it's most likely that the output language is the same as the templating system.
    it "allow for setting a custom dynamic extension" do
      FPage.add_output :fish, :format => :html, :dynamic => true, :language => "php"
      FPage.output(:fish).extension.must_equal ".fish.php"
      FPage.add_output :foul, :format => :html, :language => "php"
      FPage.output(:foul).extension(true).must_equal ".foul.php"
    end

    # What would be more useful perhaps is a way to define a custom, per output, test for "dynamicness"
    it "allow for a custom test for dynamicness"

    it "override extension even for dynamic outputs" do
      FPage.add_output :fish, :dynamic => true, :extension => "php"
      FPage.output(:fish).extension(true).must_equal ".php"
      FPage.add_output :foul, :dynamic => true, :extension => ".php"
      FPage.output(:foul).extension(true).must_equal ".php"
    end

    describe "format classes" do
      it "enable new formats" do
        assert S::Output.unknown_format?(:fishhtml)
        class FishHTMLFormat < S::Output::HTML
          provides_format :fishhtml
        end
        refute S::Output.unknown_format?(:fishhtml)
      end

      it "inherit helper classes from their superclass" do
        module CustomHelper1
          def here_is_my_custom_helper1; end
        end
        @site.register_helper CustomHelper1, :newhtml

        class NewHTMLFormat < S::Output::HTML
          provides_format :newhtml
        end

        FPage.add_output :newhtml
        page = FPage.new
        output = page.output(:newhtml)
        newhtml_context = output.context
        html_context_ancestors = page.output(:html).context.ancestors[1..-1]
        Set.new(newhtml_context.ancestors[1..-1]).must_equal Set.new(html_context_ancestors + [CustomHelper1])
      end
    end

    describe "instances" do
      before do
        FPage.add_output :pdf, :dynamic => true
        @page = FPage.new
      end

      it "generate a list of output instances tied to the page" do
        outputs = @page.outputs
        outputs.map(&:class).must_equal [FPage.output(:html), FPage.output(:pdf)]
      end

      it "generate output instances tied to the page" do
        @page.outputs.map(&:format).must_equal [:html, :pdf]
        @page.default_output.format.must_equal :html

        output = @page.output(:html)
        output.must_be_instance_of FPage.output(:html)
        output.page.must_equal @page
        output.format.must_equal :html
        refute output.dynamic?
        output.extension.must_equal ".html"

        assert @page.output(:pdf).dynamic?
      end

      it "provide a default output instance" do
        output = @page.default_output
        output.must_be_instance_of FPage.output(:html)
      end

      it "know that they provide a certain format" do
        assert @page.provides_output?(:html)
        assert @page.provides_output?(:pdf)
        refute @page.provides_output?(:xyz)
      end

      it "recognises its own output" do
        assert @page.provides_output?(@page.output(:html))
      end

      it "doesn't recognise another page's output" do
        other = FPage.new(slug: "other")
        refute @page == other
        refute @page.provides_output?(other.output(:html))
      end

      it "provide a symbol version of the output name" do
        @page.output(:html).to_sym.must_equal :html
      end

      it "return the output instance if used as an output request" do
        output = @page.output(:html)
        @page.output(output).must_equal output
      end

      it "marks identical outputs from identical pages as equal" do
        assert @page.output(:html) == @page.output(:html)
      end

      it "marks identical outputs from different pages as different" do
        page = FPage.create
        refute @page.output(:html) == page.output(:html)
      end

      it "marks different outputs from same page as different" do
        refute @page.output(:html) == @page.output(:pdf)
      end

      it "gives identical hashes for identical outputs" do
        assert @page.output(:html).hash == @page.output(:html).hash
      end
    end

    describe "with custom formats" do
      before do
        FPage.outputs :rss, :html, :json
      end

      it "be able to define their supported formats" do
        FPage.outputs.map(&:format).must_equal [:rss, :html, :json]
      end

      it "re-define the default format" do
        FPage.default_output.format.must_equal :rss
      end

      it "have tests for supported formats" do
        assert FPage.provides_output?(:html)
        assert FPage.provides_output?(:rss)
        assert FPage.provides_output?(:json)
        refute FPage.provides_output?(:xyz)
      end


      it "accept new formats when accompanied by a mime-type" do
        FPage.outputs [:xyz, {:mimetype => "application/xyz"}]
      end

      it "allow addition of a single format" do
        FPage.add_output :atom
        FPage.outputs.map(&:format).must_equal [:rss, :html, :json, :atom]
      end

      it "allow custom post-processing of render" do
        FPage.add_output :atom, :postprocess => lambda { |page, output| output.gsub(/a/, 'x') }
        page = FPage.new
        page.render(:atom).must_match %r{<xtom>}
      end
    end

    describe "with custom mime-types" do
      before do
        FPage.outputs [ :html, {:mimetype => "application/xhtml+xml"}], [:js, {:mimetype => "application/json"} ]
      end

      it "still provide the correct default format" do
        FPage.default_output.format.must_equal :html
        FPage.default_output.name.must_equal :html
      end

      it "return the custom mime-type for a output" do
        FPage.mime_type(:html).must_equal "application/xhtml+xml"
        FPage.mime_type(:js).must_equal "application/json"
        FPage.mime_type(:atom).must_equal "application/atom+xml"
      end

      it "return mime-type values from instances" do
        page = FPage.new
        page.mime_type(:html).must_equal "application/xhtml+xml"
      end

      it "allow addition of a single custom output" do
        FPage.add_output :ddd, :mimetype => "application/ddd"
        FPage.outputs.map(&:format).must_equal [:html, :js, :ddd]
        page = FPage.new
        page.mime_type(:ddd).must_equal "application/ddd"
      end
    end

    describe "with subclasses" do
      before do
        FPage.outputs :html, :rss, [:xxx, { :mimetype => "application/xxx" }]
        class FSubPage < FPage
        end
      end

      after do
        Object.send(:remove_const, :FSubPage) rescue nil
      end

      it "inherit the list of provided outputs" do
        FSubPage.outputs.must_equal FPage.outputs
      end

      it "inherit any custom mimetypes" do
        FPage.mime_type(:xxx).must_equal "application/xxx"
        FSubPage.mime_type(:xxx).must_equal "application/xxx"
      end
    end

    describe "that generate dynamic outputs" do
      it "be able to specify that a output is always dynamic" do
        FPage.add_output :rss, :dynamic => true
        assert FPage.output(:rss).dynamic?
      end

      it "be able to specify that a output with custom mimetype is always dynamic" do
        FPage.add_output :mako, :mimetype => "application/x-mako", :dynamic => true
        FPage.output(:mako).mime_type.must_equal "application/x-mako"
        assert FPage.output(:mako).dynamic?
      end

      it "be able to override the default dynamic extension" do
        FPage.add_output :html, :dynamic => true, :language => "mako"
        FPage.add_output :alternate, :mimetype => "text/html", :dynamic => true, :language => "mako"
        assert FPage.output(:html).dynamic?
        FPage.output(:html).extension.must_equal ".html.mako"
        FPage.output(:alternate).extension.must_equal ".alternate.mako"
      end
    end
  end

  describe "publishing" do
    let(:revision) { 2 }
    let(:publish_transaction) { Spontaneous::Publishing::Transaction.new(@site, revision, nil) }
    let(:renderer) { Spontaneous::Output::Template::PublishRenderer.new(publish_transaction, false) }
    let(:transaction) { mock }
    let(:page) { P.new(title: "Godot") }
    let(:output) { page.output(:html) }

    before do
      class ::P < ::Page
        field :title
      end
    end
    after do
      Object.send :remove_const, :P
    end

    it "renders static layouts for static pages" do
      P.layout { "'${ title }'" }
      transaction.expects(:store_output).with(output, false, "'Godot'")
      output.publish_page(renderer, revision, transaction)
    end

    it "renders dynamic layouts for static pages" do
      P.layout { "'${ title }' {{Time.now.to_i}}" }
      transaction.expects(:store_output).with(output, true, "'Godot' {{Time.now.to_i}}")
      output.publish_page(renderer, revision, transaction)
    end

    it "renders static layouts for dynamic pages" do
      P.controller do
        get { "Hello" }
      end
      P.layout { "'${ title }'" }
      transaction.expects(:store_output).with(output, false, "'Godot'")
      output.publish_page(renderer, revision, transaction)
    end

    it "renders dynamic layouts for dynamic pages" do
      P.controller do
        get { "Hello" }
      end
      P.layout { "'${ title }' {{Time.now.to_i}}" }
      transaction.expects(:store_output).with(output, true, "'Godot' {{Time.now.to_i}}")
      output.publish_page(renderer, revision, transaction)
    end
  end
end
