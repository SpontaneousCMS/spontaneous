# encoding: UTF-8

require 'test_helper'

ENV['RACK_ENV'] = 'test'

class FrontTest < Test::Unit::TestCase
  include StartupShutdown
  include ::Rack::Test::Methods

  class ::SitePage < Spontaneous::Page
    page_style :default
    page_style :dynamic
  end
  def self.startup
    Site.delete
    Content.delete
    Spontaneous.environment = :test
    Spontaneous.template_root = File.expand_path("../../fixtures/public/templates", __FILE__)
    @@root = SitePage.create
    @@about = SitePage.create(:slug => "about", :uid => "about")
    @@news = SitePage.create(:slug => "news", :uid => "news")
    @@root << @@about
    @@root << @@news
    @@root.save
    Content.delete_revision(1)
    Content.publish(1)
    Site.create(:published_revision => 1)
  end

  def self.shutdown
    Content.delete
    Site.delete
    Content.delete_revision(1)
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
        Page.stubs(:path).with("/about").returns(about)
        about.style = :dynamic
        # about.save
      end

      teardown do
        about.style = :default
        about.save
      end

      should "have access to the params, request & session object" do
        get '/about', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        assert last_response.ok?
        last_response.body.should == "42/peter/example.org\n"
      end
    end
  end

end
