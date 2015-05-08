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

  def asset_digest(asset_relative_path)
    digest = context._asset_environment.environment.digest
    digest.update(File.read(File.join(fixture_root, asset_relative_path)))
    digest.hexdigest
  end

  let(:y_png_digest) { asset_digest('public2/i/y.png') }

  start do
    fixture_root = File.expand_path("../../fixtures/assets", __FILE__)
    site = setup_site
    site.paths.add :assets, fixture_root / "public1", fixture_root / "public2"
    site.config.tap do |c|
      c.auto_login = 'root'
    end
    site.output_store(:Memory)
    Spontaneous::Permissions::User.delete
    user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root name", :password => "rootpass")
    user.update(:level => Spontaneous::Permissions[:editor])
    user.save.reload
    key = user.generate_access_key("127.0.0.1")

    Spontaneous::Permissions::User.stubs(:[]).with(:login => 'root').returns(user)
    Spontaneous::Permissions::User.stubs(:[]).with(user.id).returns(user)
    Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(key.key_id).returns(key)

    let(:site) { site }
    let(:fixture_root) { fixture_root }
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

  describe "development" do
    let(:context) { development_context }

    let(:a_js_digest) { asset_digest('public1/js/a.js') }
    let(:b_js_digest) { asset_digest('public2/js/b.js') }
    let(:c_js_digest) { asset_digest('public2/js/c.js') }
    let(:x_js_digest) { asset_digest('public1/x.js') }
    # these are compiled so fairly complex to calculate their digests
    # not impossible, but annoying
    let(:n_js_digest) { 'a5c86b004242d16e0dbf818068bbb248' }
    let(:m_js_digest) { 'c0f2e1c2a7d1cc9666ccb48cc9fd610e' }
    let(:all_js_digest) { '9759f54463d069b39d9c04c3e1d63745' }

    let(:a_css_digest) { 'b4ec507466566b839328b924893e80fb' }
    let(:b_css_digest) { '97b252913f48c160b1eed120f7544203' }
    let(:c_css_digest) { '3fcc1da2378a42e97cbd11cb85b8115a' }
    let(:x_css_digest) { '88b3052bb5d7723b6a6a8b628fbee34e' }
    let(:all_css_digest) { '9bac5a609f816594005b07a3a8aa2368' }

    it "includes all js dependencies" do
      result = context.scripts('js/all', 'js/m', 'js/c', 'x')
      result.must_equal [
        %|<script type="text/javascript" src="/assets/js/a.js?body=1&#{a_js_digest}"></script>|,
        %|<script type="text/javascript" src="/assets/js/b.js?body=1&#{b_js_digest}"></script>|,
        %|<script type="text/javascript" src="/assets/js/n.js?body=1&#{n_js_digest}"></script>|,
        %|<script type="text/javascript" src="/assets/js/all.js?body=1&#{all_js_digest}"></script>|,
        %|<script type="text/javascript" src="/assets/js/m.js?body=1&#{m_js_digest}"></script>|,
        %|<script type="text/javascript" src="/assets/js/c.js?body=1&#{c_js_digest}"></script>|,
        %|<script type="text/javascript" src="/assets/x.js?body=1&#{x_js_digest}"></script>|
      ].join("\n")
    end

    it "doesn't bundle js files" do
      get "/assets/js/all.js?body=1"
      result = last_response.body
      result.wont_match /elvis/
    end

    it "includes all css dependencies" do
      result = context.stylesheets('css/all', 'css/c', 'x')
      result.must_equal [
        %|<link rel="stylesheet" href="/assets/css/b.css?body=1&#{b_css_digest}" />|,
        %|<link rel="stylesheet" href="/assets/css/a.css?body=1&#{a_css_digest}" />|,
        %|<link rel="stylesheet" href="/assets/css/all.css?body=1&#{all_css_digest}" />|,
        %|<link rel="stylesheet" href="/assets/css/c.css?body=1&#{c_css_digest}" />|,
        %|<link rel="stylesheet" href="/assets/x.css?body=1&#{x_css_digest}" />|
      ].join("\n")
    end

    it "doesn't bundle js files" do
      get "/assets/css/all.css?body=1"
      result = last_response.body
      result.must_match %r(/\*\s+\*/)
    end

    it "allows for protocol agnostic absolute script urls" do
      result = context.scripts('//use.typekit.com/abcde')
      result.must_equal '<script type="text/javascript" src="//use.typekit.com/abcde"></script>'
    end

  end

  describe "preview" do
    let(:app) { Spontaneous::Rack::Back.application(site) }
    let(:context) { preview_context }

    let(:c_js_digest) { '3ab39368d6e128169ac2401bc49fcdb2' }
    let(:x_js_digest) { 'e755ffcead8090406c04b2813b9bdce9' }
    let(:n_js_digest) { '74f175e03a4bdc8c807aba4ae0314938' }
    let(:m_js_digest) { 'c0f2e1c2a7d1cc9666ccb48cc9fd610e' }
    let(:all_js_digest) { 'd782ef6abb69b1eb3e4c503478a660db' }

    let(:c_css_digest) { '3fcc1da2378a42e97cbd11cb85b8115a' }
    let(:x_css_digest) { '88b3052bb5d7723b6a6a8b628fbee34e' }
    let(:all_css_digest) { '4b837b285d3a1998c48e1811e62292d8' }

    describe "javascript" do
      it "include scripts as separate files with finger prints" do
        result = context.scripts('js/all', 'js/m.js', 'js/c.js', 'x')
        result.must_equal [
          %|<script type="text/javascript" src="/assets/js/all.js?#{all_js_digest}"></script>|,
          %|<script type="text/javascript" src="/assets/js/m.js?#{m_js_digest}"></script>|,
          %|<script type="text/javascript" src="/assets/js/c.js?#{c_js_digest}"></script>|,
          %|<script type="text/javascript" src="/assets/x.js?#{x_js_digest}"></script>|
        ].join("\n")
      end



      it "handles urls passed as an array" do
        result = context.scripts(['js/all', 'js/m.js'])
        result.must_equal [
          %|<script type="text/javascript" src="/assets/js/all.js?#{all_js_digest}"></script>|,
          %|<script type="text/javascript" src="/assets/js/m.js?#{m_js_digest}"></script>|
        ].join("\n")
      end

      it "should ignore missing files" do
        result = context.scripts('js/all', 'js/missing')
        result.must_equal [
          %|<script type="text/javascript" src="/assets/js/all.js?#{all_js_digest}"></script>|,
          '<script type="text/javascript" src="js/missing.js"></script>'
        ].join("\n")
      end

      it "should pass through absolute urls" do
        result = context.scripts('/js/all.js')
        result.must_equal '<script type="text/javascript" src="/js/all.js"></script>'
      end

      it "should bundle assets" do
        get "/assets/js/all.js"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /var a = 1/
        result.must_match /var b = 2/
        result.must_match %r{alert\("I knew it!"\);}
      end

      it "should preprocess coffeescript" do
        get "/assets/js/m.js"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /square = function\(x\)/
      end

      it "should allow access to straight js" do
        get "/assets/x.js"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{var x = 1;}
      end

      it "should use absolute URLs when encountered" do
        context = preview_context
        result = context.scripts('js/all', '//use.typekit.com/abcde', 'http://cdn.google.com/jquery.js', 'https://cdn.google.com/jquery.js')
        result.must_equal [
          %|<script type="text/javascript" src="/assets/js/all.js?#{all_js_digest}"></script>|,
          '<script type="text/javascript" src="//use.typekit.com/abcde"></script>',
          '<script type="text/javascript" src="http://cdn.google.com/jquery.js"></script>',
          '<script type="text/javascript" src="https://cdn.google.com/jquery.js"></script>'
        ].join("\n")
      end
    end

    describe "css" do
      it "include css files as separate links" do
        result = context.stylesheets('css/all', 'css/c', 'x')
        result.must_equal [
          %|<link rel="stylesheet" href="/assets/css/all.css?#{all_css_digest}" />|,
          %|<link rel="stylesheet" href="/assets/css/c.css?#{c_css_digest}" />|,
          %|<link rel="stylesheet" href="/assets/x.css?#{x_css_digest}" />|
        ].join("\n")
      end

      it "allows passing scripts as an array" do
        result = context.stylesheets(['css/all', 'css/c', 'x'])
        result.must_equal [
          %|<link rel="stylesheet" href="/assets/css/all.css?#{all_css_digest}" />|,
          %|<link rel="stylesheet" href="/assets/css/c.css?#{c_css_digest}" />|,
          %|<link rel="stylesheet" href="/assets/x.css?#{x_css_digest}" />|
        ].join("\n")
      end

      it "should bundle dependencies" do
        get "/assets/css/all.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{height: 42px;}
        result.must_match %r{width: 8px;}
      end

      it "should compile sass" do
        get "/assets/css/b.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{height: 42px;}
      end

      it "links to images" do
        get "/assets/css/image1.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background: url\(/assets/i/y\.png\)}
      end

      it "passes through non-existant images" do
        get "/assets/css/missing.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background: url\(i\/missing\.png\)}
      end

      it "can understand urls with hashes" do
        get "/assets/css/urlhash.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background: url\(/assets/i/y\.png\?query=true#hash\)}
      end

      it "embeds image data" do
        get "/assets/css/data.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background-image: url\(data:image\/png;base64,}
      end

      it "can include other assets" do
        get "/assets/css/import.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{width: 8px;}
      end
    end

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PreviewRenderer.new(site) }

      it "should allow for embedding asset images into templates" do
        result = renderer.render_string("${ asset_path 'i/y.png' }", @page.output(:html))
        result.must_equal "/assets/i/y.png?#{y_png_digest}"
      end
      it "should allow for embedding asset urls into templates" do
        result = renderer.render_string("${ asset_url 'i/y.png' }", @page.output(:html))
        result.must_equal "url(/assets/i/y.png?#{y_png_digest})"
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

    def read_script_asset(output)
      asset = Nokogiri::XML(output).at('script')['src']
      asset.gsub!(/^\/assets/, '')
      [asset, output_revision.static_asset(asset)]
    end

    def assert_script_asset(output)
      asset, value = read_script_asset(output)
      assert value, "Asset '#{asset}' missing"
      [asset, value.read]
    end

    describe "javascript" do
      let(:all_sha) { "29ced6e75f651ea6963bd2f2ffdd745e" }
      let(:x_sha) { "2b8678f6d71dc1fc0e44ad9f6a5811b3" }
      it "bundles & fingerprints local scripts" do
        result = context.scripts('js/all', 'js/m.js', 'js/c.js', 'x')
        result.must_equal [
          %(<script type="text/javascript" src="/assets/js/all-#{all_sha}.js"></script>),
          '<script type="text/javascript" src="/assets/js/m-66885c19e856373c6b9dab3a41885dbf.js"></script>',
          '<script type="text/javascript" src="/assets/js/c-0201f986795c0d9b4fb850236496359f.js"></script>',
          %(<script type="text/javascript" src="/assets/x-#{x_sha}.js"></script>)
        ].join("\n")
      end

      it "writes bundled assets to the output store" do
        result = context.scripts('js/all')
        run_copy_asset_step
        assert_script_asset(result)
      end

      it "compresses local scripts" do
        result = context.scripts('js/all')
        run_copy_asset_step
        js = assert_script_asset(result)
        js.index("\n").must_be_nil
      end

      it "bundles locals scripts and includes remote ones" do
        result = context.scripts('js/all', '//use.typekit.com/abcde', 'http://cdn.google.com/jquery.js', 'x')
        result.must_equal [
          %(<script type="text/javascript" src="/assets/js/all-#{all_sha}.js"></script>),
          '<script type="text/javascript" src="//use.typekit.com/abcde"></script>',
          '<script type="text/javascript" src="http://cdn.google.com/jquery.js"></script>',
          %(<script type="text/javascript" src="/assets/x-#{x_sha}.js"></script>)
        ].join("\n")
      end

      it "makes bundled scripts available under /assets" do
        context.scripts('js/all')
        run_copy_asset_step
        path = "/assets/js/all-#{all_sha}.js"
        get "/assets/js/all-#{all_sha}.js"
        last_response.body.must_equal read_compiled_asset(path)
      end

      it 'returns the correct content type for js' do
        html = context.scripts('js/all')
        run_copy_asset_step
        path, js = assert_script_asset(html)
        get "/assets#{path}"
        last_response.headers['Content-type'].must_equal 'application/javascript;charset=utf-8'
      end

      describe "re-use" do
        before do
          @result = context.scripts('js/all', 'x')
        end

        it "uses assets from a previous publish if present" do
          context = live_context
          def context.revision; 100 end
          revision = site.revision(context.revision)
          manifest = Spontaneous::JSON.parse File.read(site.path("assets/tmp") + "manifest.json")
          compiled = manifest[:assets][:"js/all.js"]
          ::File.open(site.path("assets/tmp")+compiled, 'w') do |file|
            file.write("var reused = true;")
          end
          result = context.scripts('js/all', 'x')
          run_copy_asset_step
          rev = revision.path("assets") + compiled
          path, js = assert_script_asset(result)
          js.must_equal "var reused = true;"
        end
      end
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

    describe "css" do
      let(:all_sha) { "a72e3c2850e95f5c89930cae40a66c29" }
      let(:x_sha)   { "88b3052bb5d7723b6a6a8b628fbee34e" }

      it "bundles & fingerprints local stylesheets" do
        result = context.stylesheets('css/all', 'css/a.css', 'x')
        result.must_equal [
          %(<link rel="stylesheet" href="/assets/css/all-#{all_sha}.css" />),
          '<link rel="stylesheet" href="/assets/css/a-46541ee6e70fb12c030698e0addc2c79.css" />',
          %(<link rel="stylesheet" href="/assets/x-#{x_sha}.css" />)
        ].join("\n")
      end

      it "ignores missing stylesheets" do
        result = context.stylesheets('css/all', '/css/notfound', 'css/notfound')
        result.must_equal [
          %(<link rel="stylesheet" href="/assets/css/all-#{all_sha}.css" />),
          '<link rel="stylesheet" href="/css/notfound" />',
          '<link rel="stylesheet" href="css/notfound" />'
        ].join("\n")
      end

      it "bundles locals scripts and includes remote ones" do
        result = context.stylesheets('css/all.css', '//stylesheet.com/responsive', 'http://cdn.google.com/normalize.css', 'x')
        result.must_equal [
          %(<link rel="stylesheet" href="/assets/css/all-#{all_sha}.css" />),
          '<link rel="stylesheet" href="//stylesheet.com/responsive" />',
          '<link rel="stylesheet" href="http://cdn.google.com/normalize.css" />',
          %(<link rel="stylesheet" href="/assets/x-#{x_sha}.css" />)
        ].join("\n")
      end

      it "makes bundled stylesheets available under /assets" do
        path = context.stylesheet_urls('css/all').first
        run_copy_asset_step
        get path
        asset_path = revision.path(path)
        last_response.body.must_equal read_compiled_asset(path)
      end

      it "compresses local styles" do
        path = context.stylesheet_urls('css/all').first
        run_copy_asset_step
        get path
        css = last_response.body
        css.index(" ").must_be_nil
      end

      # it "only bundles & compresses once" do
      #   path = context.stylesheet_urls('css/all').first
      #   run_copy_asset_step
      #   asset_path = revision.path(path)
      #   assert asset_path.exist?
      #   asset_path.open("w") do |file|
      #     file.write(".cached { }")
      #   end
      #   context.stylesheets('css/all')
      #   asset_path.read.must_equal ".cached { }"
      # end

      it "passes through non-existant images" do
        path = context.stylesheet_urls('css/missing.css').first
        run_copy_asset_step
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /background:url\(i\/missing\.png\)/
      end

      it "can include other assets" do
        path = context.stylesheet_urls('css/import').first
        run_copy_asset_step
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /width:8px/
      end
    end

    describe "images" do
      it "bundles images and links using fingerprinted asset url" do
        path = context.stylesheet_urls('css/image1').first
        run_copy_asset_step
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background:url\(/assets/i/y-#{y_png_digest}\.png\)}
      end

      it "can insert data urls for assets" do
        path = context.stylesheet_urls('css/data').first
        run_copy_asset_step
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background-image:url\(data:image/png;base64}
      end

      it "can understand urls with hashes" do
        path = context.stylesheet_urls('css/urlhash').first
        run_copy_asset_step
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background:url\(/assets/i/y-#{y_png_digest}\.png\?query=true#hash\)}
      end
    end

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PublishRenderer.new(transaction) }

      it "should allow for embedding asset images into templates" do
        result = renderer.render_string("${ asset_path 'i/y.png' }", @page.output(:html))
        result.must_equal "/assets/i/y-#{y_png_digest}.png"
      end
      it "should allow for embedding asset urls into templates" do
        result = renderer.render_string("${ asset_url 'i/y.png' }", @page.output(:html))
        result.must_equal "url(/assets/i/y-#{y_png_digest}.png)"
      end
    end
  end
end
