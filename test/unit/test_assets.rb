# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'ostruct'
require 'nokogiri'

describe "Assets" do
  include RackTestMethods

  let(:app) {Spontaneous::Rack::Back.application(site)}
  let(:transaction) { Spontaneous::Publishing::Transaction.new(site, 99,  nil) }

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

  def new_context(live, content = @page, format = :html, params = {})
    renderer = if live
                 Spontaneous::Output::Template::PublishRenderer.new(transaction)
               else
                 Spontaneous::Output::Template::PreviewRenderer.new(site)
               end
    output = content.output(format)
    context = renderer.context(output, params, nil)
    context.extend LiveSimulation if live
    # Force us into production environment
    # which is where most of the magic has to happen
    def context.development?
      false
    end
    def transaction.development?
      false
    end
    context
  end

  def live_context(content = @page, format = :html, params = {})
    new_context(true, content, format, params)
  end

  def preview_context(content = @page, format = :html, params = {})
    new_context(false, content, format, params)
  end

  def development_context(content = @page, format = :html, params = {})
    new_context(false, content, format, params).tap do |context|
      def context.development?
        true
      end
    end
  end

  start do
    asset_root = File.expand_path("../../fixtures/assets/private", __FILE__)
    site = setup_site
    site.paths.add :compiled_assets, asset_root
    site.config.tap do |c|
      c.auto_login = 'root'
    end
    site.output_store(:Memory)
    Spontaneous::Permissions::User.delete
    user = Spontaneous::Permissions::User.create(email: "root@example.com", login: "root", name: "root name", password: "rootpass")
    user.update(level: Spontaneous::Permissions[:editor])
    user.save.reload
    key = user.generate_access_key("127.0.0.1")

    Spontaneous::Permissions::User.stubs(:[]).with(login: 'root').returns(user)
    Spontaneous::Permissions::User.stubs(:[]).with(user.id).returns(user)
    Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(key.key_id).returns(key)

    let(:site) { site }
    let(:asset_root) { asset_root }
    let(:user) { user }
    let(:key) { key }
  end

  finish do
    teardown_site
  end

  before do
    @page = Page.create
  end

  after do
    tmp = site.path('assets/tmp')
    FileUtils.rm_r(tmp) if tmp.exist?
    Content.delete
  end

  describe "Preview context" do
    it "should not be flagged as publishing" do
      refute preview_context.publishing?
    end
    it "should not have the development? flag set" do
      refute preview_context.development?
    end
  end

  describe "Development context" do
    it "should not be flagged as publishing" do
      refute development_context.publishing?
    end

    it "should have the development? flag set" do
      assert development_context.development?
    end
  end

  describe "Publishing context" do
    it "be flagged as publishing" do
      Spontaneous.stubs(:production?).returns(true)
      assert live_context.publishing?
    end

    it "be flagged as live" do
      Spontaneous.stubs(:production?).returns(true)
      assert live_context.live?
    end

    it "be flagged as publishing" do
      assert live_context.publishing?
    end
  end

  let(:assets) {
    %w(
      js/a-5e2f65f63.js
      js/b-8ae4b63fa.js
      css/a-798ae4b63.css
      css/b-63ab5f068.css
      css/not_in_manifest.css
      js/not_in_manifest.js
      y-28ce8c9b9.png
    )
  }

  describe "manifests" do
    let(:manifests) { Spontaneous::Asset::Manifests.new([asset_root], '/assets') }

    it "can return an absolute path to an asset file" do
      manifests.path('js/a.js').must_equal ::File.join(asset_root, 'js/a-5e2f65f63.js')
    end
    it "can return an absolute path to an asset file not in the manifest" do
      manifests.path('js/not_in_manifest.js').must_equal ::File.join(asset_root, 'js/not_in_manifest.js')
    end
  end

  describe "development" do
    let(:app) { Spontaneous::Rack::Back.application(site) }
    let(:context) { preview_context }

    it "handles scripts passed as an array" do
      result = context.scripts(['js/a', 'js/b'])
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a-5e2f65f63.js"></script>|,
        %|<script type="text/javascript" src="/assets/js/b-8ae4b63fa.js"></script>|,
      ].join("\n")
    end

    it "includes all script dependencies" do
      result = context.scripts('js/a', 'js/b')
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a-5e2f65f63.js"></script>|,
        %|<script type="text/javascript" src="/assets/js/b-8ae4b63fa.js"></script>|,
      ].join("\n")
    end

    it "ignores/accepts extensions" do
      result = context.scripts('js/a.js', 'js/b.js')
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a-5e2f65f63.js"></script>|,
        %|<script type="text/javascript" src="/assets/js/b-8ae4b63fa.js"></script>|,
      ].join("\n")
    end

    it "finds js files on disk but not in manifest" do
      result = context.scripts('js/a', 'js/b', 'js/not_in_manifest')
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a-5e2f65f63.js"></script>|,
        %|<script type="text/javascript" src="/assets/js/b-8ae4b63fa.js"></script>|,
        %|<script type="text/javascript" src="/assets/js/not_in_manifest.js"></script>|,
      ].join("\n")
    end

    it "includes all stylesheets dependencies" do
      result = context.stylesheets('css/a', 'css/b')
      result.must_equal [
        %|<link rel="stylesheet" href="/assets/css/a-798ae4b63.css" />|,
        %|<link rel="stylesheet" href="/assets/css/b-63ab5f068.css" />|,
      ].join("\n")
    end

    it "includes all stylesheets dependencies passed as an array" do
      result = context.stylesheets(['css/a', 'css/b'])
      result.must_equal [
        %|<link rel="stylesheet" href="/assets/css/a-798ae4b63.css" />|,
        %|<link rel="stylesheet" href="/assets/css/b-63ab5f068.css" />|,
      ].join("\n")
    end

    it "resolves asset files" do
      assets.each do |a|
        get "/assets/#{a}"
        last_response.body.must_equal ::File.binread(asset_root / a)
      end
    end

    it "allows for protocol agnostic absolute script urls" do
      result = context.scripts('//use.typekit.com/abcde')
      result.must_equal '<script type="text/javascript" src="//use.typekit.com/abcde"></script>'
    end

    it "should ignore missing js files" do
      result = context.scripts('js/a', 'js/missing')
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a-5e2f65f63.js"></script>|,
        %|<script type="text/javascript" src="js/missing"></script>|
      ].join("\n")
    end

    it "should ignore missing css files" do
      result = context.stylesheets('css/a', 'css/missing')
      result.must_equal [
        %|<link rel="stylesheet" href="/assets/css/a-798ae4b63.css" />|,
        %|<link rel="stylesheet" href="css/missing" />|,
      ].join("\n")
    end

    it "should use absolute script URLs when encountered" do
      result = context.scripts('js/a', '//use.typekit.com/abcde', 'http://cdn.google.com/jquery.js', 'https://cdn.google.com/jquery.js')
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a-5e2f65f63.js"></script>|,
        '<script type="text/javascript" src="//use.typekit.com/abcde"></script>',
        '<script type="text/javascript" src="http://cdn.google.com/jquery.js"></script>',
        '<script type="text/javascript" src="https://cdn.google.com/jquery.js"></script>'
      ].join("\n")
    end

    it "should use absolute stylesheet URLs when encountered" do
      result = context.stylesheets('css/a', '//use.typekit.com/abcde.css', 'http://cdn.google.com/jquery.css', 'https://cdn.google.com/jquery.css')
      result.must_equal [
        %|<link rel="stylesheet" href="/assets/css/a-798ae4b63.css" />|,
        '<link rel="stylesheet" href="//use.typekit.com/abcde.css" />',
        '<link rel="stylesheet" href="http://cdn.google.com/jquery.css" />',
        '<link rel="stylesheet" href="https://cdn.google.com/jquery.css" />'
      ].join("\n")
    end
  end

  describe "preview" do
    let(:app) { Spontaneous::Rack::Back.application(site) }
    let(:context) { preview_context }

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PreviewRenderer.new(site) }

      it "should allow for embedding asset images into templates" do
        result = renderer.render_string("${ asset_path 'img/y.png' }", @page.output(:html))
        result.must_equal "/assets/y-28ce8c9b9.png"
      end
      it "should allow for embedding asset urls into templates" do
        result = renderer.render_string("${ asset_url 'img/y.png' }", @page.output(:html))
        result.must_equal "url(/assets/y-28ce8c9b9.png)"
      end
    end
  end

  describe "publishing" do
    let(:app) { Spontaneous::Rack::Front.application(site) }
    let(:context) { live_context }
    let(:revision) { site.revision(context.revision) }
    let(:store) { site.output_store }
    let(:output_revision) { store.revision(revision.to_i) }

    before do
      site.stubs(:published_revision).returns(99)
    end

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PublishRenderer.new(transaction) }

      it "should allow for embedding asset images into templates" do
        result = renderer.render_string("${ asset_path 'img/y.png' }", @page.output(:html))
        result.must_equal "/assets/y-28ce8c9b9.png"
      end
      it "should allow for embedding asset urls into templates" do
        result = renderer.render_string("${ asset_url 'img/y.png' }", @page.output(:html))
        result.must_equal "url(/assets/y-28ce8c9b9.png)"
      end
    end

    def assert_script_asset(path)
      value = output_revision.static_asset(path)
      assert value.read.force_encoding("ASCII-8BIT") == ::File.binread(asset_root / path)
    end

    it "writes bundled assets to the output store" do
      run_copy_asset_step
      assets.each do |a|
        assert_script_asset(a)
      end
    end

    it "doesn't copy asset manifests to the output store" do
      value = output_revision.static_asset(site.asset_mount_path / 'manifest.json')
      assert value.nil?
    end

    def run_copy_asset_step
      transaction = context._renderer.transaction
      step = Spontaneous::Publishing::Steps::CopyAssets.new(transaction)
      step.call
    end

    def read_compiled_asset(path)
      transaction = context._renderer.transaction
      dir =  transaction.asset_environment.manifest.asset_compilation_dir
      read_path = File.expand_path File.join(dir, path.gsub(/^\/assets/, ''))
      ::File.read(read_path)
    end
  end

  describe "deployment compiler" do
    let(:src) { File.expand_path("../../fixtures/assets/private", __FILE__) }
    let(:dest) { Dir.mktmpdir }
    let(:compiler) { Spontaneous::Asset::Compiler.new(src, dest) }
    let(:manifest_file) { File.join(src, 'manifest.json') }
    let(:manifest_json) { File.read(manifest_file) }
    let(:manifest) { JSON.parse(manifest_json) }

    after do
      FileUtils.rm_r(dest)
    end

    it "should raise an error if src dir doesn't exist" do
      assert_raises(RuntimeError) { Spontaneous::Asset::Compiler.new("/watchtadoing/now", dest) }
    end

    it "should copy any files in the manifest" do
      compiler.run
      manifest.values.each do |asset|
        assert File.exist?(File.join(dest, asset)), "#{asset} does not exist"
      end
    end

    it "should copy & fingerprint any files not in the manifest" do
      compiler.run
      [
        "css/not_in_manifest-e27639ec152498da599e15630f1b1f41.css",
        "js/not_in_manifest-736b54bd070158b8a7e84b73217fac36.js",
        "not_in_manifest-9e7a728b7e18f1e236af7ffe97beaa03.png",
      ].each do |asset|
        assert File.exist?(File.join(dest, asset)), "#{asset} does not exist"
      end
    end

    it "should generate a manifest that includes all files" do
      manifest = compiler.run
      compiled = {
        "css/a.css" => "css/a-798ae4b63.css",
        "css/b.css" => "css/b-63ab5f068.css",
        "css/not_in_manifest.css" => "css/not_in_manifest-e27639ec152498da599e15630f1b1f41.css",
        "js/a.js" => "js/a-5e2f65f63.js",
        "js/b.js" => "js/b-8ae4b63fa.js",
        "js/not_in_manifest.js" => "js/not_in_manifest-736b54bd070158b8a7e84b73217fac36.js",
        "img/y.png" => "y-28ce8c9b9.png",
        "not_in_manifest.png" => "not_in_manifest-9e7a728b7e18f1e236af7ffe97beaa03.png",
      }
      manifest.must_equal compiled
      compiled.values.each do |asset|
        assert File.exist?(File.join(dest, asset)), "#{asset} does not exist"
      end
    end

    it "should use the default fingerprinter if passed nil" do
      manifest = compiler.run(nil)
      compiled = {
        "css/a.css" => "css/a-798ae4b63.css",
        "css/b.css" => "css/b-63ab5f068.css",
        "css/not_in_manifest.css" => "css/not_in_manifest-e27639ec152498da599e15630f1b1f41.css",
        "js/a.js" => "js/a-5e2f65f63.js",
        "js/b.js" => "js/b-8ae4b63fa.js",
        "js/not_in_manifest.js" => "js/not_in_manifest-736b54bd070158b8a7e84b73217fac36.js",
        "img/y.png" => "y-28ce8c9b9.png",
        "not_in_manifest.png" => "not_in_manifest-9e7a728b7e18f1e236af7ffe97beaa03.png",
      }
      manifest.must_equal compiled
    end

    it "should allow for defining a custom fingerprint naming proc" do
      manifest = compiler.run(proc { |base, md5, ext| "#{md5[0..5]}_#{base}#{ext}" })
      compiled = {
        "css/a.css" => "css/a-798ae4b63.css",
        "css/b.css" => "css/b-63ab5f068.css",
        "css/not_in_manifest.css" => "css/e27639_not_in_manifest.css",
        "js/a.js" => "js/a-5e2f65f63.js",
        "js/b.js" => "js/b-8ae4b63fa.js",
        "js/not_in_manifest.js" => "js/736b54_not_in_manifest.js",
        "img/y.png" => "y-28ce8c9b9.png",
        "not_in_manifest.png" => "9e7a72_not_in_manifest.png",
      }
      manifest.must_equal compiled
      compiled.values.each do |asset|
        assert File.exist?(File.join(dest, asset)), "#{asset} does not exist"
      end
    end

    it "should write the manifest to the destination dir" do
      compiler.run
      compiled = {
        "css/a.css" => "css/a-798ae4b63.css",
        "css/b.css" => "css/b-63ab5f068.css",
        "css/not_in_manifest.css" => "css/not_in_manifest-e27639ec152498da599e15630f1b1f41.css",
        "js/a.js" => "js/a-5e2f65f63.js",
        "js/b.js" => "js/b-8ae4b63fa.js",
        "js/not_in_manifest.js" => "js/not_in_manifest-736b54bd070158b8a7e84b73217fac36.js",
        "img/y.png" => "y-28ce8c9b9.png",
        "not_in_manifest.png" => "not_in_manifest-9e7a728b7e18f1e236af7ffe97beaa03.png",
      }
      m = JSON.parse(::File.read(::File.join(dest, 'manifest.json')))
      m.must_equal compiled
    end
  end
end
