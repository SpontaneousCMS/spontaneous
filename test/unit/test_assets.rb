# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'ostruct'
require 'shine'

class AssetTest < MiniTest::Spec


  class Context < OpenStruct
    include Spontaneous::Render::PublishContext

    # simulate a production + publishing environment
    def live?
      true
    end

    # usually set as part of the render process
    def revision
      99
    end
  end

  def new_context(content = nil, format = :html, params = {})
    Context.new(content, format, params)
  end

  def setup
    @site = setup_site
    @fixture_root = File.expand_path("../../fixtures/assets", __FILE__)
    @site.paths.add :public, @fixture_root / "public1", @fixture_root / "public2"
  end

  def teardown
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

  context "Javascript assets" do
    should "be compressed in live environment" do
      files = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      Shine.expects(:compress_files).with(files, :js, {}).once.returns("var A;\nvar B;\n")
      context = new_context
      result = context.scripts("/js/a", "/js/b")
      result.should =~ /src="\/rev\/5dde6b3e04ce364ef23f51048006e5dd7e6f62ad\.js"/
      on_disk = Spontaneous::Render.revision_root(context.revision) / "rev/5dde6b3e04ce364ef23f51048006e5dd7e6f62ad.js"
      assert File.exist?(on_disk)
      File.read(on_disk).should == "var A;\nvar B;\n"
    end

    should "use a cache to make sure identical file lists are only compressed once" do
      files1 = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      files2 = [@fixture_root / "public2/js/b.js", @fixture_root / "public2/js/c.js"]
      Shine.expects(:compress_files).with(files1, :js, {}).once.returns("var A;\nvar B;\n")
      Shine.expects(:compress_files).with(files2, :js, {}).once.returns("var B;\nvar C;\n")
      context = new_context
      S::Render.with_publishing_renderer do
        result = context.scripts("/js/a", "/js/b")
        result = context.scripts("/js/a", "/js/b")
        result = context.scripts("/js/b", "/js/c")
        result = context.scripts("/js/b", "/js/c")
        result.should =~ /src="\/rev\/1458221916fde33ec803fbbae20af8ded0ee2ca1\.js"/
      end
    end
    should "support UTF8 scripts" do
      files = [@fixture_root / "public1/js/a.js", @fixture_root / "public2/js/b.js"]
      Shine.expects(:compress_files).with(files, :js, {}).once.returns("var A = \"\xC2\";\nvar B;\n".force_encoding("ASCII-8BIT"))
      context = new_context
      result = context.scripts("/js/a", "/js/b")
    end

    should "support scripts with full urls" do
      context = new_context
      result = context.scripts("http://jquery.com/jquery.js")
      result.should =~ /src="http:\/\/jquery.com\/jquery.js"/
    end
  end

  context "Stylesheet assets" do
    should "be compressed in live environment" do
      files = [@fixture_root / "public1/css/a.scss", @fixture_root / "public2/css/b.scss"]
      context = new_context
      context.expects(:compress_css_string).with(<<-CSS).returns(["/* compressed */\n", "df3e2b3fa3409d8ca37faac7da80349098f0b28a"])
.a{width:8px}
.c { color: #fff; }
.b{height:42px}
      CSS
      result = context.stylesheets("/css/a", "/css/c", "/css/b")
      result.should =~ /href="\/rev\/df3e2b3fa3409d8ca37faac7da80349098f0b28a\.css"/
      on_disk = Spontaneous::Render.revision_root(context.revision) / "rev/df3e2b3fa3409d8ca37faac7da80349098f0b28a.css"

      assert File.exist?(on_disk)
      File.read(on_disk).should == "/* compressed */\n"
    end

    should "use a cache to make sure identical file lists are only compressed once" do
      context = new_context
      context.expects(:compress_css_string).with(<<-CSS).once.returns(["/* compressed1 */\n", "20aac22ae20e78ef1574a3a6635fa353148e9d9a"])
.a{width:8px}
.b{height:42px}
      CSS
      context.expects(:compress_css_string).with(<<-CSS).once.returns(["/* compressed2 */\n", "77ec1b6ee2907c65cf316b99b59c8cf8006dcddf"])
.a{width:8px}
.c { color: #fff; }
      CSS
#       Shine.expects(:compress_string).with(<<-CSS, :css, {}).once.returns("/* compressed1 */\\n")
# .a{width:8px}
# .b{height:42px}
#       CSS
#       Shine.expects(:compress_string).with(<<-CSS, :css, {}).once.returns("/* compressed2 */\\n")
# .a{width:8px}
# .c { color: #fff; }
#       CSS
      S::Render.with_publishing_renderer do
        result = context.stylesheets("/css/a", "/css/b")
        result = context.stylesheets("/css/a", "/css/b")
        result.should =~ /href="\/rev\/20aac22ae20e78ef1574a3a6635fa353148e9d9a\.css"/
        result = context.stylesheets("/css/a", "/css/c")
        result = context.stylesheets("/css/a", "/css/c")
        result.should =~ /href="\/rev\/77ec1b6ee2907c65cf316b99b59c8cf8006dcddf\.css"/
      end
    end

    should "support UTF8 styles" do
      context = new_context
      context.expects(:compress_css_string).with(<<-CSS).once.returns(["/* \xC2 */\n", "13234"])
.a{width:8px}
.b{height:42px}
      CSS
#       Shine.expects(:compress_string).with(<<-CSS, :css, {}).once.returns("/* \\xC2 */\\n".force_encoding("ASCII-8BIT"))
# .a{width:8px}
# .b{height:42px}
#       CSS
      result = context.stylesheets("/css/a", "/css/b")
    end
  end
end
