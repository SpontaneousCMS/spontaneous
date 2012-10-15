# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class AssetBundler < MiniTest::Spec
  include ::Rack::Test::Methods

  def app
    Spontaneous::Rack::Back.application
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

  context "CMS asset bundler" do
    should "compile Javascript into any destination directory ddd" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root, :compress => false)
      compiler.compile
      compiled_js_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.js"].first
      js = File.read(compiled_js_path)
      js.should =~ /var simple = "yes";/
      js.should =~ /var basic/
      js.should =~ /var complex/
      js.should =~ /complex = "#{Date.today.day}"/
      js.should =~ /var simple_subdir = "yes";/
      js.should =~ /var complex_subdir;/
      js.should =~ /complex_subdir = "subdir\/#{Date.today.day}";/
    end

    should "produce compressed Javascript on demand" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root, :compress => true)
      compiler.compile
      compiled_js_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.js"].first
      js = File.read(compiled_js_path)
      # hard to test because we don't know exactly what the uglifier is going to do
      js.should =~ /var (\w);\1="yes"/
      js.should =~ /var (\w);\1="#{Date.today.day}"/
      js.should =~ /var (\w);\1="subdir\/#{Date.today.day}"/
    end

    should "compile CSS into any destination directory" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root, :compress => false)
      compiler.compile
      compiled_css_path = Dir["#{@site.root}/public/@spontaneous/assets/*.css"].first
      css = File.read(compiled_css_path)
      css.should =~ /\.simple \{\s+color: #aaa/
      css.should =~ /\.basic \{\s+color: #aabbcc/
      css.should =~ /\.complex \{\s+color: #ddeeff;\s*width: #{Date.today.day}px/
      css.should =~ /\.subdir\.simple \{\s+color: #000;/
      css.should =~ /\.subdir\.complex \{\s+color: #aaaaaa;\s+height: #{Date.today.day}px/
    end

    should "produce compressed CSS by default" do
      compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root)
      compiler.compile
      compiled_css_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.css"].first
      css = File.read(compiled_css_path)
      css.should =~ /\.simple\{color:#aaa\}/
      css.should =~ /\.basic\{color:#aabbcc\}/
      css.should =~ /\.complex\{color:#ddeeff;width:#{Date.today.day}px\}/
      css.should =~ /\.subdir\.simple\{color:#000\}/
      css.should =~ /\.subdir\.complex\{color:#aaaaaa;height:#{Date.today.day}px\}/
    end
  end

  context "Development mode editing app" do
    setup do
      @page = ::S::Content.create
    end

    teardown do
      Content.delete
    end

    context "unauthorised users" do
      should "load a non-fingerprinted CSS file" do
        get "/@spontaneous/#{@page.id}"
        assert_login_page
        last_response.body.should =~ %r{/@spontaneous/css/spontaneous\.css}
      end
    end

    context "authorised users" do
      setup do
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
      teardown do
        Content.delete
        Spontaneous::Permissions::User.delete
      end
    end

    should "be able to load spontaneous.css" do
      get "/@spontaneous/css/spontaneous.css"
      assert last_response.ok?, "Recieved a #{last_response.status} instead of 200"
      last_response.body.should =~ /#content/
    end
  end

  context "Production mode editing app" do
    setup do
      @compiler = Spontaneous::Asset::AppCompiler.new(fixture_dir, @site.root)
      @compiler.compile
      @page = ::S::Content.create
    end

    teardown do
      Content.delete
    end

    should "be able to retrieve compiled assets" do
      css_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.css"].first
      css_file = ::File.basename(css_path)
      get "/@spontaneous/assets/#{css_file}"
      assert last_response.ok?, "Recieved #{last_response.status} instead of 200 for /@spontaneous/assets/#{css_file}"
    end

    context "unauthorised users" do
      should "load a fingerprinted CSS file" do
        get "/@spontaneous/#{@page.id}"
        assert_login_page
        css_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.css"].first
        css_file = ::File.basename(css_path)
        last_response.body.should =~ %r{/@spontaneous/assets/#{ css_file }}
      end

      should "load fingerpringed JS files" do
        get "/@spontaneous/#{@page.id}"
        assert_login_page

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/login*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.should =~ %r{/@spontaneous/assets/#{ js_file }}

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/vendor/jquery*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.should =~ %r{/@spontaneous/assets/vendor/#{ js_file }}
      end
    end

    context "authorised users aaaa" do
      setup do
        Spontaneous.stubs(:reload!)
        @user = Spontaneous::Permissions::User.create(:email => "test@example.com", :login => "test", :name => "test name", :password => "testpass")
        @user.update(:level => Spontaneous::Permissions[:editor])
        @user.save
        config = mock()
        config.stubs(:reload_classes).returns(false)
        config.stubs(:auto_login).returns('test')
        config.stubs(:default_charset).returns('utf-8')
        config.stubs(:publishing_method).returns(:immediate)
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

      teardown do
        Content.delete
        Spontaneous::Permissions::User.delete
      end

      should "load fingerpringed JS files" do
        get "/@spontaneous/"
        assert last_response.ok?, "User should be authorised but recieving a #{last_response.status}"

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/spontaneous*.js"].first
        js_file = ::File.basename(js_path)
        js_size = ::File.size(js_path)
        last_response.body.should =~ %r{\["/@spontaneous/assets/#{ js_file }", *#{js_size}\]}

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/require*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.should =~ %r{/@spontaneous/assets/#{ js_file }}

        js_path = Dir["#{@site.root}/public/@spontaneous/assets/vendor/jquery*.js"].first
        js_file = ::File.basename(js_path)
        last_response.body.should =~ %r{/@spontaneous/assets/vendor/#{ js_file }}
      end
    end

    should "be able to load spontaneous.css" do
      get "/@spontaneous/css/spontaneous.css"
      assert last_response.ok?, "Recieved a #{last_response.status} instead of 200"
      last_response.body.should =~ /#content/
    end
  end
end
