# encoding: UTF-8

require 'test_helper'

ENV['RACK_ENV'] = 'test'


class FrontTest < Test::Unit::TestCase
  include StartupShutdown
  include ::Rack::Test::Methods

  class SitePage < Spontaneous::Page
    page_style :default
    page_style :dynamic
    box :pages
  end

  def self.startup
    Site.delete
    Content.delete
    Spontaneous.environment = :test

    @saved_revision_root = Spontaneous.revision_root
    @saved_root = Spontaneous.root
    Spontaneous.root = File.expand_path('../../fixtures/example_application', __FILE__)
    @@revision_root = "#{Dir.tmpdir}/spontaneous-tests/#{Time.now.to_i}"
    `mkdir -p #{@@revision_root}`
    Spontaneous.revision_root = @@revision_root

    Spontaneous.template_root = File.expand_path("../../fixtures/public/templates", __FILE__)

    @@root = SitePage.create
    @@about = SitePage.create(:slug => "about", :uid => "about")
    @@news = SitePage.create(:slug => "news", :uid => "news")
    @@dynamic = SitePage.create(:slug => "dynamic", :uid => "dynamic")
    @@dynamic.style = :dynamic
    @@root.pages << @@about
    @@root.pages << @@news
    @@root.pages << @@dynamic
    @@root.save

    Content.delete_revision(1)

    # silence_logger {
      Site.publish_all
    # }
  end

  def self.shutdown
    Content.delete
    Site.delete
    Content.delete_revision(1)
    Spontaneous.revision_root = @saved_revision_root
    Spontaneous.root = @saved_root
    FileUtils.rm_rf(@@revision_root)
    # Object.send(:remove_const, :SitePage)
  end

  def setup
    @saved_template_root = Spontaneous.template_root
    # see http://benprew.posterous.com/testing-sessions-with-sinatra
    app.send(:set, :sessions, false)
  end

  def teardown
    Spontaneous.template_root = @saved_template_root
  end

  def app
    Spontaneous::Rack::Front.application
  end

  def root
    @@root
  end

  def about
    @@about
  end

  def news
    @@news
  end

  def dynamic
    @@dynamic
  end

  def revision_root
    @@revision_root
  end

  def session
    last_request.env['rack.session']
  end

  context "Public pages" do
    setup do
    end

    teardown do
    end

    should "return a 404 if asked for a non-existant page" do
      get '/not-bloody-likely'
      assert last_response.status == 404
    end

    should "provide root when asked" do
      get '/'
      assert last_response.ok?
      last_response.body.should == "/.html\n"
    end

    should "be available through their path" do
      get '/about'
      assert last_response.ok?
      last_response.body.should == "/about.html\n"
      last_response.content_type.should == "text/html;charset=utf-8"
    end

    should "be available through their path with explicit format" do
      get '/about.html'
      assert last_response.ok?
      last_response.body.should == "/about.html\n"
      last_response.content_type.should == "text/html;charset=utf-8"
    end

    should "honor the format of the request" do
      get '/about.pdf'
      assert last_response.ok?
      last_response.body.should == "/about.pdf\n"
      last_response.content_type.should == "application/pdf"
    end

    should "raise a 404 if asked for a format not provided by the page" do
      get '/about.time'
      assert last_response.status == 404
    end

    context "Showing alternate content" do
      setup do
        Page.stubs(:path).with("/about").returns(about)
        Page.stubs(:path).with("/news").returns(news)
      end

      should "render an alternate page if passed a page" do
        about.stubs(:show).returns(news)
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "render an alternate page if passed a path" do
        about.stubs(:show).returns("/news")
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "render an alternate page if passed a uid with a #" do
        about.stubs(:show).returns("#news")
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "render an alternate page if passed a uid" do
        about.stubs(:show).returns("news")
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "return not found of #show returns an invalid uid or path" do
        about.stubs(:show).returns("caterpillars")
        get '/about'
        assert last_response.status == 404
      end

      # should "handle anything that responds to #render(format)" do
      #   show = mock()
      #   show.stubs(:render).returns("mocked")
      #   about.stubs(:show).returns(show)
      #   get '/about'
      #   last_response.body.should == "mocked"
      # end
    end

    context "Redirects" do
      setup do
        Page.stubs(:path).with("/about").returns(about)
      end

      should "respond appropriatly to redirects to path" do
        about.stubs(:redirect).returns("/news")
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].should == "http://example.org/news"
      end

      should "recognise a :temporary redirect" do
        about.stubs(:redirect).returns([ "/news", :temporary ])
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].should == "http://example.org/news"
      end

      should "recognise a :permanent redirect" do
        about.stubs(:redirect).returns([ "/news", :permanent ])
        get '/about'
        assert last_response.status == 301
        last_response.headers["Location"].should == "http://example.org/news"
      end

      should "correctly apply numeric status codes" do
        about.stubs(:redirect).returns([ "/news", 307 ])
        get '/about'
        last_response.headers["Location"].should == "http://example.org/news"
        assert last_response.status == 307
      end
    end

    context "Templates" do
      setup do
        # Page.stubs(:path).with("/about").returns(about)
        # about.style = :dynamic
        # about.save
      end

      teardown do
        # about.style = :default
        # about.save
      end

      should "have access to the params, request & session object" do
        get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        assert last_response.ok?
        last_response.body.should == "42/peter/example.org\n"
      end

      context "caching" do
        setup do
          Spontaneous::Render.cache_templates = true
          @cache_file = "#{Spontaneous.revision_dir(1)}/html/dynamic/index.html.rb"
        end

        teardown do
          Spontaneous::Render.cache_templates = false
        end

        should "use pre-rendered versions of the templates" do
          dummy_content = 'cached-version/#{session[\'user_id\']}'
          dummy_template = File.join(revision_root, "dummy.html.cut")
          File.open(dummy_template, 'w') { |f| f.write(dummy_content) }
          Spontaneous::Render.stubs(:output_path).returns(dummy_template)
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          last_response.body.should == "cached-version/42"
        end

        should "cache templates as ruby files" do
          @cache_file = "#{Spontaneous.revision_dir(1)}/html/dynamic/index.html.rb"
          FileUtils.rm(@cache_file) if File.exists?(@cache_file)
          File.exists?(@cache_file).should be_false
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          # puts `ls -l #{File.dirname(@cache_file)}`
          File.exists?(@cache_file).should be_true
          File.open(@cache_file, 'w') { |f| f.write('_buf << %Q`@cache_filed-version/#{params[\'wendy\']}`;')}
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          last_response.body.should == "@cache_filed-version/peter"
          FileUtils.rm(@cache_file)
        end

        should "not cache templates if caching turned off" do
          Spontaneous::Render.cache_templates = false
          FileUtils.rm(@cache_file) if File.exists?(@cache_file)
          File.exists?(@cache_file).should be_false
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          File.exists?(@cache_file).should be_false
        end
      end
    end
  end
end
