# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'ostruct'

describe "Assets" do
  include RackTestMethods

  let(:app) {Spontaneous::Rack::Back.application(site)}

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
                 Spontaneous::Output::Template::PublishRenderer.new(site)
               else
                 Spontaneous::Output::Template::PreviewRenderer.new(site)
               end
    output = content.output(format)
    context = renderer.context(output, params, nil)
    context.extend LiveSimulation if live
    context.class_eval do
      # Force us into production environment
      # which is where most of the magic has to happen
      def development?
        false
      end
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
      context.class_eval do
        def development?
          true
        end
      end
    end
  end

  def asset_digest(asset_relative_path)
    digest = context.asset_environment.environment.digest
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
    let(:n_js_digest) { '74f175e03a4bdc8c807aba4ae0314938' }
    let(:m_js_digest) { 'dd35b142dc75b6ec15b2138e9e91c0c3' }
    let(:all_js_digest) { 'd406fc3c21d90828a2f0a718c89e8d99' }

    let(:a_css_digest) { '7b04d295476986c24d8c77245943e5b9' }
    let(:b_css_digest) { '266643993e14da14f2473d45f003bd2c' }
    let(:c_css_digest) { 'fc8ba0d0aae64081dc00b8444a198fb8' }
    let(:x_css_digest) { '2560aec2891794825eba770bf84823fb' }
    let(:all_css_digest) { 'cf61c624b91b9ea126804291ac55bd5d' }

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

    let(:c_js_digest) { 'f669550dd7e10e9646ad781f44756950' }
    let(:x_js_digest) { '6b4c9176b2838a4949a18284543fc19c' }
    let(:n_js_digest) { '74f175e03a4bdc8c807aba4ae0314938' }
    let(:m_js_digest) { 'dd35b142dc75b6ec15b2138e9e91c0c3' }
    let(:all_js_digest) { 'cd1f681752f5038421be0bc5ea0e855d' }

    let(:c_css_digest) { 'fc8ba0d0aae64081dc00b8444a198fb8' }
    let(:x_css_digest) { '2560aec2891794825eba770bf84823fb' }
    let(:all_css_digest) { 'bb2c289a27b3d5d4467dde6d60722fd3' }

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
    let(:progress) { Spontaneous::Publishing::Progress::Silent.new }

    def publish_assets(revision)
      context.asset_environment.manifest.compile!
      Spontaneous::Publishing::Steps::CopyAssets.new(site, revision, [], progress).call
    end

    before do
      FileUtils.rm_f(Spontaneous.revision_dir) if File.exist?(Spontaneous.revision_dir)
      system "ln -nfs #{revision.root} #{Spontaneous.revision_dir}"
      publish_assets(context.revision)
    end

    after do
      revision.path("assets").rmtree if revision.path("assets").exist?
    end

    describe "javascript" do
      let(:all_sha) { "ed62549e8edc1f61a1e27136602f01d9" }
      let(:x_sha) { "66e92be1e412458f6ff02f4c5dd9beb1" }
      it "bundles & fingerprints local scripts" do
        result = context.scripts('js/all', 'js/m.js', 'js/c.js', 'x')
        result.must_equal [
          %(<script type="text/javascript" src="/assets/js/all-#{all_sha}.js"></script>),
          '<script type="text/javascript" src="/assets/js/m-a5be7324bc314d5cf470a59c3732ef10.js"></script>',
          '<script type="text/javascript" src="/assets/js/c-c24bcbb4f9647b078cc919746aa7fc3a.js"></script>',
          %(<script type="text/javascript" src="/assets/x-#{x_sha}.js"></script>)
        ].join("\n")
      end

      it "writes bundled assets to the revision directory" do
        result = context.scripts('js/all')
        asset_path = revision.path("assets/js/all-#{all_sha}.js")
        assert asset_path.exist?
      end

      it "compresses local scripts" do
        result = context.scripts('js/all')
        asset_path = revision.path("assets/js/all-#{all_sha}.js")
        js = asset_path.read
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
        get "/assets/js/all-#{all_sha}.js"
        asset_path = revision.path("assets/js/all-#{all_sha}.js")
        last_response.body.must_equal asset_path.read
      end

      it "only bundles & compresses once" do
        context.scripts('js/all')
        asset_path = revision.path("assets/js/all-#{all_sha}.js")
        assert asset_path.exist?
        asset_path.open("w") do |file|
          file.write("var cached = true;")
        end
        context.scripts('js/all')
        asset_path.read.must_equal "var cached = true;"
      end
      describe "re-use" do
        before do
          @result = context.scripts('js/all', 'x')
        end

        it "uses assets from a previous publish if present" do
          context = live_context
          def context.revision; 100 end
          revision = site.revision(context.revision)
          publish_assets(context.revision)
          manifest = Spontaneous::JSON.parse File.read(site.path("assets/tmp") + "manifest.json")
          compiled = manifest[:assets][:"js/all.js"]
          ::File.open(site.path("assets/tmp")+compiled, 'w') do |file|
            file.write("var reused = true;")
          end
          result = context.scripts('js/all', 'x')
          rev = revision.path("assets") + compiled
          File.read(rev).must_equal "var reused = true;"
        end
      end
    end

    describe "css" do
      let(:all_sha) { "2e17f25ddeba996223a6cd1e28e7a319" }
      let(:x_sha)   { "2560aec2891794825eba770bf84823fb" }

      it "bundles & fingerprints local stylesheets" do
        result = context.stylesheets('css/all', 'css/a.css', 'x')
        result.must_equal [
          %(<link rel="stylesheet" href="/assets/css/all-#{all_sha}.css" />),
          '<link rel="stylesheet" href="/assets/css/a-0164c6d5b696ec2f2c5e70cade040da8.css" />',
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
        get path
        asset_path = revision.path(path)
        last_response.body.must_equal asset_path.read
      end

      it "compresses local styles" do
        path = context.stylesheet_urls('css/all').first
        asset_path = revision.path(path)
        css = asset_path.read
        css.index(" ").must_be_nil
      end

      it "only bundles & compresses once" do
        path = context.stylesheet_urls('css/all').first
        asset_path = revision.path(path)
        assert asset_path.exist?
        asset_path.open("w") do |file|
          file.write(".cached { }")
        end
        context.stylesheets('css/all')
        asset_path.read.must_equal ".cached { }"
      end

      it "passes through non-existant images" do
        path = context.stylesheet_urls('css/missing.css').first
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /background:url\(i\/missing\.png\)/
      end

      it "can include other assets" do
        path = context.stylesheet_urls('css/import').first
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /width:8px/
      end
    end

    describe "images" do
      it "bundles images and links using fingerprinted asset url" do
        path = context.stylesheet_urls('css/image1').first
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background:url\(/assets/i/y-#{y_png_digest}\.png\)}

        asset_path = revision.path("/assets/i/y-#{y_png_digest}.png")
        assert asset_path.exist?
      end

      it "can insert data urls for assets" do
        path = context.stylesheet_urls('css/data').first
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background-image:url\(data:image/png;base64}
      end

      it "can understand urls with hashes" do
        path = context.stylesheet_urls('css/urlhash').first
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background:url\(/assets/i/y-#{y_png_digest}\.png\?query=true#hash\)}
        asset_path = revision.path("/assets/i/y-#{y_png_digest}.png")
        assert asset_path.exist?
      end
    end

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PublishRenderer.new(site) }

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
