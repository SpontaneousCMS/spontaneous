# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "AssetBundler" do
  include RackTestMethods

  def app
    Spontaneous::Rack::Back.application(@site)
  end

  def fixture_dir
    File.expand_path("../../fixtures/asset_pipeline", __FILE__)
  end

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  describe "CMS asset bundler" do
    it "compile Javascript into any destination directory ddd" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root, :compress => false)
      compiler.compile
      compiled_js_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.js"].first
      js = File.read(compiled_js_path)
      js.must_match /var simple = "yes";/
      js.must_match /var simple_subdir = "yes";/
    end

    it "produce compressed Javascript on demand" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root, :compress => true)
      compiler.compile
      compiled_js_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.js"].first
      js = File.read(compiled_js_path)
      # hard to test because we don't know exactly what the uglifier is going to do
      js.must_match /var simple="yes",simple_subdir="yes"/
    end

    it "compile CSS into any destination directory" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root, :compress => false)
      compiler.compile
      compiled_css_path = Dir["#{@site.root}/public/@spontaneous/assets/*.css"].first
      css = File.read(compiled_css_path)
      css.must_match /\.simple \{\s+color: #aaa/
      css.must_match /\.basic \{\s+color: #abc/
      css.must_match /\.complex \{\s+color: #def;\s*width: #{Date.today.day}px/
      css.must_match /\.subdir\.simple \{\s+color: #000;/
      css.must_match /\.subdir\.complex \{\s+color: #aaa;\s+height: #{Date.today.day}px/
    end

    it "produce compressed CSS by default" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root)
      compiler.compile
      compiled_css_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.css"].first
      css = File.read(compiled_css_path)
      css.must_match /\.simple\{color:#aaa\}/
      css.must_match /\.basic\{color:#abc\}/
      css.must_match /\.complex\{color:#def;width:#{Date.today.day}px\}/
      css.must_match /\.subdir\.simple\{color:#000\}/
      css.must_match /\.subdir\.complex\{color:#aaa;height:#{Date.today.day}px\}/
    end
  end

  describe "Development mode editing app" do
    before do
      @page = Content.create
    end

    after do
      Content.delete
    end

    describe "unauthorised users" do
      it "load a non-fingerprinted CSS file" do
        get "/@spontaneous/#{@page.id}"
        assert_login_page
        last_response.body.must_match %r{/@spontaneous/css/spontaneous\.css}
      end
    end

    describe "authorised users" do
      before do
        @user = Spontaneous::Permissions::User.create(:email => "test@example.com", :login => "test", :name => "test name", :password => "testpass")
        @site.config.auto_login @user.login

        @key = "c5AMX3r5kMHX2z9a5ExLKjAmCcnT6PFf22YQxzb4Codj"
        @key.stubs(:user).returns(@user)
        @key.stubs(:key_id).returns(@key)
        @user.stubs(:access_keys).returns([@key])

        Spontaneous::Permissions::User.stubs(:[]).with(:login => 'test').returns(@user)
        Spontaneous::Permissions::User.stubs(:[]).with(@user.id).returns(@user)
        Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(@key).returns(@key)
        Spontaneous::Permissions::AccessKey.stubs(:valid?).with(@key, @user).returns(true)

      end
      after do
        Content.delete
        Spontaneous::Permissions::User.delete
      end
    end

    it "be able to load spontaneous.css" do
      get "/@spontaneous/css/spontaneous.css"
      assert last_response.ok?, "Recieved a #{last_response.status} instead of 200"
      last_response.body.must_match /#content/
    end
  end

  describe "Production mode editing app" do
    before do
      @compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root)
      @compiler.compile
      @page = Content.create
    end

    after do
      Content.delete
    end

    it "be able to retrieve compiled assets" do
      css_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.css"].first
      css_file = ::File.basename(css_path)
      get "/@spontaneous/assets/#{css_file}"
      assert last_response.ok?, "Recieved #{last_response.status} instead of 200 for /@spontaneous/assets/#{css_file}"
    end

    describe "unauthorised users" do
      it "load a fingerprinted CSS file" do
        get "/@spontaneous/#{@page.id}"
        assert_login_page
        css_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.css"].first
        css_file = ::File.basename(css_path)
        last_response.body.must_match %r{/@spontaneous/assets/#{ css_file }}
      end

      it "load fingerpringed JS files" do
        get "/@spontaneous/#{@page.id}"
        assert_login_page

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/login*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.must_match %r{/@spontaneous/assets/#{ js_file }}

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/vendor/jquery*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.must_match %r{/@spontaneous/assets/vendor/#{ js_file }}
      end
    end

    describe "authorised users aaaa" do
      before do
        Spontaneous.stubs(:reload!)
        @user = Spontaneous::Permissions::User.create(:email => "test@example.com", :login => "test", :name => "test name", :password => "testpass")
        @user.update(:level => Spontaneous::Permissions[:editor])
        @user.save
        config = mock()
        config.stubs(:reload_classes).returns(false)
        config.stubs(:auto_login).returns('test')
        config.stubs(:default_charset).returns('utf-8')
        config.stubs(:background_mode).returns(:immediate)
        config.stubs(:services).returns(nil)
        config.stubs(:site_domain).returns('example.org')
        config.stubs(:site_id).returns('example_org')
        config.stubs(:site_id).returns('example_org')
        @site.stubs(:config).returns(config)

        @key = "c5AMX3r5kMHX2z9a5ExLKjAmCcnT6PFf22YQxzb4Codj"
        @key.stubs(:user).returns(@user)
        @key.stubs(:key_id).returns(@key)
        @user.stubs(:access_keys).returns([@key])

        Spontaneous::Permissions::User.stubs(:[]).with(:login => 'test').returns(@user)
        Spontaneous::Permissions::User.stubs(:[]).with(@user.id).returns(@user)
        Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(@key).returns(@key)
        Spontaneous::Permissions::AccessKey.stubs(:valid?).with(@key, @user).returns(true)
      end

      after do
        Content.delete
        Spontaneous::Permissions::User.delete
      end

      it "load fingerpringed JS files" do
        get "/@spontaneous/"
        assert last_response.ok?, "User it be authorised but recieving a #{last_response.status}"

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.js"].first
        js_file = ::File.basename(js_path)
        js_size = ::File.size(js_path)
        last_response.body.must_match %r{\["/@spontaneous/assets/#{ js_file }", *#{js_size}\]}

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/require*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.must_match %r{/@spontaneous/assets/#{ js_file }}

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/vendor/jquery*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.must_match %r{/@spontaneous/assets/vendor/#{ js_file }}
      end
    end

    it "be able to load spontaneous.css" do
      get "/@spontaneous/css/spontaneous.css"
      assert last_response.ok?, "Recieved a #{last_response.status} instead of 200"
      last_response.body.must_match /#content/
    end
  end
end
