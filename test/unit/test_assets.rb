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
end
