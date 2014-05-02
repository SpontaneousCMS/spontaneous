# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Plugins" do
  include RackTestMethods


  start do
    @site = setup_site

    ::Page.box :box1
    klass =  Class.new(::Page) do
      layout :from_plugin
    end
    Object.send(:const_set, :LocalPage, klass)
    klass =  Class.new(::Piece) do
      style :from_plugin
    end
    Object.send(:const_set, :LocalPiece, klass)

    plugin_dir = File.expand_path("../../fixtures/plugins/schema_plugin", __FILE__)
    plugin = Spontaneous.instance.load_plugin plugin_dir
    plugin.init!
    plugin.load!
  end

  finish do
    Object.send(:remove_const, :LocalPage) rescue nil
    Object.send(:remove_const, :LocalPiece) rescue nil
    teardown_site
  end

  def app
    Spontaneous::Rack.application(@site)
  end


  before do
    S::State.delete
    Content.delete
    @site = Spontaneous.instance
    @site.background_mode = :immediate
    page = ::Page.new
    page.save

  end

  after do
    S::State.delete
    Content.delete
  end

  it "load their init.rb file" do
    assert $set_in_init
  end

  describe "with static files" do
    before do
      @static = %w(css/plugin.css js/plugin.js subdir/image.gif static.html)
    end

    it "be able to provide them under their namespace in editing mode" do
      Spontaneous.mode = :back
      @static.each do |file|
        get "/schema_plugin/#{file}"
        assert last_response.ok?, "Static file /schema_plugin/#{file} returned error code #{last_response.status}"
        last_response.body.must_equal File.basename(file) + "\n"
      end
    end

    it "be able to provide them under their namespace in public mode" do
      Spontaneous.mode = :front
      @static.each do |file|
        get "/schema_plugin/#{file}"
        assert last_response.ok?, "Static file /schema_plugin/#{file} returned error code #{last_response.status}"
        last_response.body.must_equal File.basename(file) + "\n"
      end
    end

    it "look for and parse sass templates" do
      Spontaneous.mode = :back
      get "/schema_plugin/subdir/sass.css"
      assert last_response.ok?, "Static file /schema_plugin/subdir/sass.css returned error code #{last_response.status}"
      last_response.body.must_match %r{^\s+color: #005a55;}
      last_response.body.must_match %r{^\s+padding: 42px;}
    end
  end

  describe "with schemas" do
    it "make content classes available to rest of app" do
      defined?(::SchemaPlugin).must_equal "constant"
      ::SchemaPlugin::External.fields.length.must_equal 1
      page  = ::Page.new
      piece = ::SchemaPlugin::External.new(:a => "A Field")
      page.box1 << piece
      piece.render.must_equal "plugins/templates/external.html.cut\n"
    end
  end
end
