# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'ostruct'

describe "Assets" do
  include RackTestMethods

  def app
    Spontaneous::Rack::Back.application
  end

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
                 Spontaneous::Output::Template::PublishRenderer.new
               else
                 Spontaneous::Output::Template::PreviewRenderer.new
               end
    output = content.output(format)
    context = renderer.context(output, params)
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


  start do
    fixture_root = File.expand_path("../../fixtures/assets", __FILE__)
    site = setup_site
    site.paths.add :assets, fixture_root / "public1", fixture_root / "public2"
    site.config.tap do |c|
      c.auto_login = 'root'
    end
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

    it "includes all js dependencies" do
      result = context.scripts('js/all', 'js/m', 'js/c', 'x')
      result.must_equal [
        '<script type="text/javascript" src="/assets/js/a.js?body=1"></script>',
        '<script type="text/javascript" src="/assets/js/b.js?body=1"></script>',
        '<script type="text/javascript" src="/assets/js/n.js?body=1"></script>',
        '<script type="text/javascript" src="/assets/js/all.js?body=1"></script>',
        '<script type="text/javascript" src="/assets/js/m.js?body=1"></script>',
        '<script type="text/javascript" src="/assets/js/c.js?body=1"></script>',
        '<script type="text/javascript" src="/assets/x.js?body=1"></script>'
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
        '<link rel="stylesheet" href="/assets/css/b.css?body=1" />',
        '<link rel="stylesheet" href="/assets/css/a.css?body=1" />',
        '<link rel="stylesheet" href="/assets/css/all.css?body=1" />',
        '<link rel="stylesheet" href="/assets/css/c.css?body=1" />',
        '<link rel="stylesheet" href="/assets/x.css?body=1" />'
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
    let(:app) { Spontaneous::Rack::Back.application }
    let(:context) { preview_context }

    describe "javascript" do
      it "include scripts as separate files" do
        result = context.scripts('js/all', 'js/m.js', 'js/c.js', 'x')
        result.must_equal [
          '<script type="text/javascript" src="/assets/js/all.js"></script>',
          '<script type="text/javascript" src="/assets/js/m.js"></script>',
          '<script type="text/javascript" src="/assets/js/c.js"></script>',
          '<script type="text/javascript" src="/assets/x.js"></script>'
        ].join("\n")
      end



      it "handles urls passed as an array" do
        result = context.scripts(['js/all', 'js/m.js'])
        result.must_equal [
          '<script type="text/javascript" src="/assets/js/all.js"></script>',
          '<script type="text/javascript" src="/assets/js/m.js"></script>'
        ].join("\n")
      end

      it "should ignore missing files" do
        result = context.scripts('js/all', 'js/missing')
        result.must_equal [
          '<script type="text/javascript" src="/assets/js/all.js"></script>',
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
        result.must_match /alert\("I knew it!"\);/
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
        result.must_match /var x = 1;/
      end

      it "should use absolute URLs when encountered" do
        context = preview_context
        result = context.scripts('js/all', '//use.typekit.com/abcde', 'http://cdn.google.com/jquery.js', 'https://cdn.google.com/jquery.js')
        result.must_equal [
          '<script type="text/javascript" src="/assets/js/all.js"></script>',
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
          '<link rel="stylesheet" href="/assets/css/all.css" />',
          '<link rel="stylesheet" href="/assets/css/c.css" />',
          '<link rel="stylesheet" href="/assets/x.css" />'
        ].join("\n")
      end

      it "allows passing scripts as an array" do
        result = context.stylesheets(['css/all', 'css/c', 'x'])
        result.must_equal [
          '<link rel="stylesheet" href="/assets/css/all.css" />',
          '<link rel="stylesheet" href="/assets/css/c.css" />',
          '<link rel="stylesheet" href="/assets/x.css" />'
        ].join("\n")
      end

      it "should bundle dependencies" do
        get "/assets/css/all.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /height: 42px;/
        result.must_match /width: 8px;/
      end

      it "should compile sass" do
        get "/assets/css/b.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /height: 42px;/
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
        result.must_match /background: url\(i\/missing\.png\)/
      end

      it "embeds image data" do
        get "/assets/css/data.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /background-image: url\(data:image\/png;base64,/
      end

      it "can include other assets" do
        get "/assets/css/import.css"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match /width: 8px;/
      end
    end

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PreviewRenderer.new }

      it "should allow for embedding asset images into templates" do
        result = renderer.render_string("${ asset_path 'i/y.png' }", @page.output(:html))
        result.must_equal "/assets/i/y.png"
      end
      it "should allow for embedding asset urls into templates" do
        result = renderer.render_string("${ asset_url 'i/y.png' }", @page.output(:html))
        result.must_equal "url(/assets/i/y.png)"
      end
    end
  end

  describe "publishing" do
    let(:app) { Spontaneous::Rack::Front.application }
    let(:context) { live_context }
    let(:revision) { S::Revision.new(context.revision) }

    before do
      FileUtils.rm_f(Spontaneous.revision_dir) if File.exist?(Spontaneous.revision_dir)
      system "ln -nfs #{revision.root} #{Spontaneous.revision_dir}"
      # FileUtils.ln_s(revision.root, Spontaneous.revision_dir)
    end

    after do
      revision.path("assets").rmtree if revision.path("assets").exist?
    end

    describe "javascript" do
      it "bundles & fingerprints local scripts" do
        result = context.scripts('js/all', 'js/m.js', 'js/c.js', 'x')
        result.must_equal [
          '<script type="text/javascript" src="/assets/js/all-22505bbfb6293f6996de75f281c97fe7.js"></script>',
          '<script type="text/javascript" src="/assets/js/m-7daf13cf52ad1c0306a55982228f0dc3.js"></script>',
          '<script type="text/javascript" src="/assets/js/c-3183d7b34185b5095c679ecdbe50fd92.js"></script>',
          '<script type="text/javascript" src="/assets/x-61d00c5233906a8f06ac5f236c1200a6.js"></script>'
        ].join("\n")
      end

      it "writes bundled assets to the revision directory" do
        result = context.scripts('js/all')
        asset_path = revision.path("assets/js/all-22505bbfb6293f6996de75f281c97fe7.js")
        assert asset_path.exist?
      end

      it "compresses local scripts" do
        result = context.scripts('js/all')
        asset_path = revision.path("assets/js/all-22505bbfb6293f6996de75f281c97fe7.js")
        js = asset_path.read
        js.index("\n").must_be_nil
      end

      it "bundles locals scripts and includes remote ones" do
        result = context.scripts('js/all', '//use.typekit.com/abcde', 'http://cdn.google.com/jquery.js', 'x')
        result.must_equal [
          '<script type="text/javascript" src="/assets/js/all-22505bbfb6293f6996de75f281c97fe7.js"></script>',
          '<script type="text/javascript" src="//use.typekit.com/abcde"></script>',
          '<script type="text/javascript" src="http://cdn.google.com/jquery.js"></script>',
          '<script type="text/javascript" src="/assets/x-61d00c5233906a8f06ac5f236c1200a6.js"></script>'
        ].join("\n")
      end

      it "makes bundled scripts available under /assets" do
        context.scripts('js/all')
        get "/assets/js/all-22505bbfb6293f6996de75f281c97fe7.js"
        asset_path = revision.path("assets/js/all-22505bbfb6293f6996de75f281c97fe7.js")
        last_response.body.must_equal asset_path.read
      end

      it "only bundles & compresses once" do
        context.scripts('js/all')
        asset_path = revision.path("assets/js/all-22505bbfb6293f6996de75f281c97fe7.js")
        assert asset_path.exist?
        asset_path.open("w") do |file|
          file.write("var cached = true;")
        end
        context.scripts('js/all')
        asset_path.read.must_equal "var cached = true;"
      end
    end

    describe "css" do
      it "bundles & fingerprints local stylesheets" do
        result = context.stylesheets('css/all', 'css/a.css', 'x')
        result.must_equal [
          '<link rel="stylesheet" href="/assets/css/all-5a2bcfb191dd15394a00b096d5978593.css" />',
          '<link rel="stylesheet" href="/assets/css/a-603fe41a590a542843a288327e6bf9b7.css" />',
          '<link rel="stylesheet" href="/assets/x-0d6f7e6ce6f1553544acb14682c8eb07.css" />'
        ].join("\n")
      end

      it "ignores missing stylesheets" do
        result = context.stylesheets('css/all', '/css/notfound', 'css/notfound')
        result.must_equal [
          '<link rel="stylesheet" href="/assets/css/all-5a2bcfb191dd15394a00b096d5978593.css" />',
          '<link rel="stylesheet" href="/css/notfound" />',
          '<link rel="stylesheet" href="css/notfound" />'
        ].join("\n")
      end

      it "bundles locals scripts and includes remote ones" do
        result = context.stylesheets('css/all.css', '//stylesheet.com/responsive', 'http://cdn.google.com/normalize.css', 'x')
        result.must_equal [
          '<link rel="stylesheet" href="/assets/css/all-5a2bcfb191dd15394a00b096d5978593.css" />',
          '<link rel="stylesheet" href="//stylesheet.com/responsive" />',
          '<link rel="stylesheet" href="http://cdn.google.com/normalize.css" />',
          '<link rel="stylesheet" href="/assets/x-0d6f7e6ce6f1553544acb14682c8eb07.css" />'
        ].join("\n")
      end

      it "makes bundled scripts available under /assets" do
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
        result.must_match %r{background:url\(/assets/i/y-9cf98219611ef5a9fdf0d970af30084a\.png\)}

        asset_path = revision.path("/assets/i/y-9cf98219611ef5a9fdf0d970af30084a.png")
        assert asset_path.exist?
      end

      it "can insert data urls for assets" do
        path = context.stylesheet_urls('css/data').first
        get path
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        result = last_response.body
        result.must_match %r{background-image:url\(data:image/png;base64}
      end
    end

    describe "templates" do
      let(:renderer)  { Spontaneous::Output::Template::PublishRenderer.new }

      it "should allow for embedding asset images into templates" do
        result = renderer.render_string("${ asset_path 'i/y.png' }", @page.output(:html))
        result.must_equal "/assets/i/y-9cf98219611ef5a9fdf0d970af30084a.png"
      end
      it "should allow for embedding asset urls into templates" do
        result = renderer.render_string("${ asset_url 'i/y.png' }", @page.output(:html))
        result.must_equal "url(/assets/i/y-9cf98219611ef5a9fdf0d970af30084a.png)"
      end
    end
  end
end
