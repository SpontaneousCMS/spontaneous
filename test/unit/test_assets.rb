# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'ostruct'

class AssetTest < MiniTest::Spec

  module LiveSimulation
    # simulate a production + publishing environment
    def live?
      true
    end
    # usually set as part of the render process
    def revision
      99
    end
  end

  def new_context(content = @page, format = :html, params = {})
    renderer = Spontaneous::Output::Template::PublishRenderer.new
    output = content.output(format)
    context = renderer.context(output, params)
    context.extend LiveSimulation
    context
  end

  def setup
    @site = setup_site
    @fixture_root = File.expand_path("../../fixtures/assets", __FILE__)
    @site.paths.add :public, @fixture_root / "public1", @fixture_root / "public2"
    @page = Page.create
  end

  def teardown
    Content.delete
    teardown_site
  end

  context "Publishing context" do
    should "be flagged as live" do
      Spontaneous.stubs(:production?).returns(true)
      new_context.live?.should be_true
    end

    should "be flagged as publishing" do
      new_context.publishing?.should be_true
    end
  end

  Compression = Spontaneous::Output::Assets::Compression

  context "Javascript assets" do
    should "be compressed in live environment" do
      files = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      src = files.map { |p| File.read(p) }.join
      Compression.expects(:compress_js).with(src, {}).once.returns("var A;\nvar B;\n")
      context = new_context
      result = context.scripts("/js/a", "/js/b")
      result.should =~ /src="\/rev\/5dde6b3e04ce364ef23f51048006e5dd7e6f62ad\.js"/
      on_disk = Spontaneous::Output.revision_root(context.revision) / "rev/5dde6b3e04ce364ef23f51048006e5dd7e6f62ad.js"
      assert File.exist?(on_disk)
      File.read(on_disk).should == "var A;\nvar B;\n"
    end

    should "use a cache to make sure identical file lists are only compressed once" do
      files1 = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      files2 = [@fixture_root / "public2/js/b.js", @fixture_root / "public2/js/c.js"]
      src1 = files1.map { |p| File.read(p) }.join
      src2 = files2.map { |p| File.read(p) }.join
      Compression.expects(:compress_js).with(src1, {}).once.returns("var A;\nvar B;\n")
      Compression.expects(:compress_js).with(src2, {}).once.returns("var B;\nvar C;\n")
      context = new_context
      result = context.scripts("/js/a", "/js/b")
      result = context.scripts("/js/a", "/js/b")
      result = context.scripts("/js/b", "/js/c")
      result = context.scripts("/js/b", "/js/c")
      result.should =~ /src="\/rev\/1458221916fde33ec803fbbae20af8ded0ee2ca1\.js"/
    end

    should "be compressed when publishing & passed a force_compression option" do
      files = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      src = files.map { |p| File.read(p) }.join
      Compression.expects(:compress_js).with(src, {}).once.returns("var A;\nvar B;\n")
      context = new_context
      context.stubs(:live?).returns(false)
      context.stubs(:publishing?).returns(true)
      result = context.scripts("/js/a", "/js/b", :force_compression => true)

      Compression.expects(:compress_js).with(src, {}).never
      context.stubs(:publishing?).returns(false)
      result = context.scripts("/js/a", "/js/b", :force_compression => true)
    end

    should "support UTF8 scripts" do
      files = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      src = files.map { |p| File.read(p) }.join
      Compression.expects(:compress_js).with(src, {}).once.returns("var A = \"\xC2\";\nvar B;\n")
      context = new_context
      result = context.scripts("/js/a", "/js/b")
    end

    should "support scripts with full urls" do
      context = new_context
      result = context.scripts("http://jquery.com/jquery.js")
      result.should =~ /src="http:\/\/jquery.com\/jquery.js"/
    end
  end

  context "CoffeeScript assets" do
    should "be compiled & compressed in live environment" do
      files = [@fixture_root / "public1/js/m.js", @fixture_root / "public2/js/n.js"]
      Compression.expects(:compress_js).with(regexp_matches(/square = function/), {}).once.returns("var A;\nvar B;\n")
      context = new_context
      result = context.scripts("/js/m", "/js/n")
      result.should =~ /src="\/rev\/5dde6b3e04ce364ef23f51048006e5dd7e6f62ad\.js"/
      on_disk = Spontaneous::Output.revision_root(context.revision) / "rev/5dde6b3e04ce364ef23f51048006e5dd7e6f62ad.js"
      assert File.exist?(on_disk)
      File.read(on_disk).should == "var A;\nvar B;\n"
    end

    should "be correctly compiled when mixed with plain js" do
      Compression.expects(:compress_js).with(regexp_matches(/square = function/), {}).once.returns("var A;\nvar B;\n")
      context = new_context
      result = context.scripts("/js/a", "/js/m", "/js/n", "/js/b")
    end
  end

  context "Stylesheet assets" do
    should "be compressed in live environment" do
      files = [@fixture_root / "public1/css/a.scss", @fixture_root / "public2/css/b.scss"]
      context = new_context
      Compression.expects(:compress_css).with(<<-CSS).once.returns("/* compressed */\n")
.a{width:8px}
.c { color: #fff; }
.b{height:42px}
      CSS
      result = context.stylesheets("/css/a", "/css/c", "/css/b")
      result.should =~ /href="\/rev\/df3e2b3fa3409d8ca37faac7da80349098f0b28a\.css"/
      on_disk = Spontaneous::Output.revision_root(context.revision) / "rev/df3e2b3fa3409d8ca37faac7da80349098f0b28a.css"

      assert File.exist?(on_disk)
      File.read(on_disk).should == "/* compressed */\n"
    end

    should "be compressed if publishing and passed a force option" do
      files = [@fixture_root / "public1/css/a.scss", @fixture_root / "public2/css/b.scss"]
      context = new_context
      m = Module.new do
        def live?; false; end
        def publishing?; true; end
      end
      context.extend m
      context.live?.should be_false
      Compression.expects(:compress_css).with(anything).once.returns("/* compressed */\n")
      result = context.stylesheets("/css/a", "/css/c", "/css/b", {:force_compression => true})

      def context.publishing?; false; end
      context.publishing?.should be_false
      Compression.expects(:compress_css_string).with(anything).never
      result = context.stylesheets("/css/a", "/css/c", "/css/b", {:force_compression => true})
    end

    should "use a cache to make sure identical file lists are only compressed once" do
      context = new_context
      Compression.expects(:compress_css).with(<<-CSS).once.returns("/* compressed1 */\n")
.a{width:8px}
.b{height:42px}
      CSS
      Compression.expects(:compress_css).with(<<-CSS).once.returns("/* compressed2 */\n")
.a{width:8px}
.c { color: #fff; }
      CSS
      result = context.stylesheets("/css/a", "/css/b")
      result = context.stylesheets("/css/a", "/css/b")
      result.should =~ /href="\/rev\/20aac22ae20e78ef1574a3a6635fa353148e9d9a\.css"/
      result = context.stylesheets("/css/a", "/css/c")
      result = context.stylesheets("/css/a", "/css/c")
      result.should =~ /href="\/rev\/77ec1b6ee2907c65cf316b99b59c8cf8006dcddf\.css"/
    end

    should "support UTF8 styles" do
      context = new_context
      Compression.expects(:compress_css).with(<<-CSS).once.returns("/* \xC2 */\n")
.a{width:8px}
.b{height:42px}
      CSS
      result = context.stylesheets("/css/a", "/css/b")
    end
  end
end
