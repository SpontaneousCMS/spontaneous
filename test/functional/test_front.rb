# encoding: UTF-8

require 'test_helper'

ENV['RACK_ENV'] = 'test'


class FrontTest < MiniTest::Spec
  include ::Rack::Test::Methods

  def self.startup
  end

  def self.shutdown
  end

  def setup
    @saved_template_root = Spontaneous.template_root
    Site.publishing_method = :immediate
  end

  def teardown
    Spontaneous.template_root = @saved_template_root
  end

  def app
    Spontaneous::Rack::Front.application
  end

  def root
    @root
  end

  def about
    @about
  end

  def news
    @news
  end

  def subpage
    @sub
  end

  def dynamic
    @dynamic
  end

  def revision_root
    @revision_root
  end

  def session
    last_request.env['rack.session']
  end

  context "Public pages" do
    setup do
      Spot::Schema.reset!

      @saved_revision_root = Spontaneous.revision_root
      @saved_root = Spontaneous.root

      root = File.expand_path('../../fixtures/example_application', __FILE__)
      Spontaneous.root = root

      Spontaneous.init(:environment => :test, :mode => :front)

      Site.publishing_method = :immediate
      State.delete
      Content.delete
      Change.delete

      class ::SitePage < Spontaneous::Page
        layout :default
        layout :dynamic
        box :pages

        attr_accessor :status
      end

      class ::SubPage < SitePage; end


      # see http://benprew.posterous.com/testing-sessions-with-sinatra
      app.send(:set, :sessions, false)

      @revision_root = "#{Dir.tmpdir}/spontaneous-tests/#{Time.now.to_i}"
      `mkdir -p #{@revision_root}`
      Spontaneous.revision_root = @revision_root

      self.template_root = File.expand_path("../../fixtures/public/templates", __FILE__)

      @root = ::SitePage.create
      @about = ::SitePage.create(:slug => "about", :uid => "about")
      @sub = ::SubPage.create(:slug => "now", :uid => "now")
      @news = ::SitePage.create(:slug => "news", :uid => "news")
      @dynamic = ::SitePage.create(:slug => "dynamic", :uid => "dynamic")
      @dynamic.layout = :dynamic
      @root.pages << @about
      @root.pages << @news
      @root.pages << @dynamic
      @about.pages << @sub
      @root.save

      Content.delete_revision(1) rescue nil

      Spontaneous.logger.silent! {
        Site.publish_all
      }
    end

    teardown do
      Object.send(:remove_const, :SitePage) rescue nil
      Object.send(:remove_const, :SubPage) rescue nil
      Content.delete
      State.delete
      Content.delete_revision(1)
      Spontaneous.revision_root = @saved_revision_root
      Spontaneous.root = @saved_root
      FileUtils.rm_rf(@revision_root)
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
      @about.class.stubs(:formats).returns([:html, :pdf])
      get '/about.pdf'
      assert last_response.ok?
      last_response.body.should == "/about.pdf\n"
      last_response.content_type.should == "application/pdf"
    end

    should "provide the default format of the page if none is explicitly given" do
      @about.class.stubs(:formats).returns([:rss, :html])
      get '/about'
      assert last_response.ok?
      last_response.content_type.should == ::Rack::Mime.mime_type('.rss')
      last_response.body.should == "/about.rss\n"
    end

    should "return a custom content type if one is defined" do
      @about.class.formats [{:html => "application/xhtml+xml"}]
      get '/about'
      assert last_response.ok?
      last_response.content_type.should == "application/xhtml+xml;charset=utf-8"
      last_response.body.should == "/about.html\n"
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
        about.stubs(:request_show).returns(news)
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "render an alternate page if passed a path" do
        about.stubs(:request_show).returns("/news")
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "render an alternate page if passed a uid with a #" do
        about.stubs(:request_show).returns("#news")
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "render an alternate page if passed a uid" do
        about.stubs(:request_show).returns("news")
        get '/about'
        assert last_response.ok?
        last_response.body.should == "/news.html\n"
      end

      should "return not found of #request_show returns an invalid uid or path" do
        about.stubs(:request_show).returns("caterpillars")
        get '/about'
        assert last_response.status == 404
      end

      # should "handle anything that responds to #render(format)" do
      #   show = mock()
      #   show.stubs(:render).returns("mocked")
      #   about.stubs(:request_show).returns(show)
      #   get '/about'
      #   last_response.body.should == "mocked"
      # end
    end

    context "Redirects" do
      setup do
        Page.stubs(:path).with("/about").returns(about)
      end

      should "respond appropriatly to redirects to path" do
        about.stubs(:request_redirect).returns("/news")
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].should == "http://example.org/news"
      end

      should "recognise a :temporary redirect" do
        about.stubs(:request_redirect).returns([ "/news", :temporary ])
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].should == "http://example.org/news"
      end

      should "recognise a :permanent redirect" do
        about.stubs(:request_redirect).returns([ "/news", :permanent ])
        get '/about'
        assert last_response.status == 301
        last_response.headers["Location"].should == "http://example.org/news"
      end

      should "correctly apply numeric status codes" do
        about.stubs(:request_redirect).returns([ "/news", 307 ])
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

    context "Model controllers" do
      setup do
        class ::TestController < Spontaneous::PageController
          get '/' do
            "Magic"
          end
        end
        SitePage.controller :comments do
          get '/' do
            "Success"
          end

          get '/page' do
            page
          end
          get '/format' do
            format.to_s
          end
        end

        SitePage.controller :status do
          get '/:status' do
            page.status = params[:status]
            page
          end

          post '/:status' do
            page.status = params[:status]
            page
          end
        end

        SitePage.controller :test, ::TestController

        SitePage.controller :test2, ::TestController do
          get "/block" do
            "Block"
          end
        end

        Page.stubs(:path).with("/about").returns(about)
        Page.stubs(:path).with("/about/now").returns(subpage)
      end

      teardown do
        SitePage.send(:remove_const, :StatusController) rescue nil
        SitePage.send(:remove_const, :TestController) rescue nil
        SitePage.send(:remove_const, :Test2Controller) rescue nil
        Object.send(:remove_const, :TestController) rescue nil
      end

      should "not be used unless necessary" do
        get "/about"
        assert last_response.ok?
        last_response.body.should == about.render
      end

      should "be recognised" do
        get "/about/@comments"
        assert last_response.ok?
        last_response.body.should == "Success"
      end

      should "render the page correctly if action returns page object" do
        get "/about/@comments/page"
        assert last_response.ok?
        last_response.body.should == about.render
      end

      should "return 404 if trying unknown namespace" do
        get "/about/@missing/action"
        assert last_response.status == 404
      end

      should "respond to multiple namespaces" do
        get "/about/@status/good"
        assert last_response.ok?
        last_response.body.should == about.render
        about.status.should == "good"
      end

      should "accept POST requests" do
        post "/about/@status/good"
        assert last_response.ok?
        last_response.body.should == about.render
        about.status.should == "good"
      end

      should "return 404 unless post request has an action" do
        Page.expects(:path).with("/about").never
        post "/about"
        assert last_response.status == 404
      end

      should "return 404 for post requests to unknown actions" do
        post "/about/@status/missing/action"
        assert last_response.status == 404
      end

      # probably the wrong place to test this -- should be in units -- but what the heck
      should "be able to generate urls for actions" do
        about.action_url(:status, "/good").should == "/about/@status/good"
      end

      should "pass the format onto the page if the action returns it to the render call" do
        about.stubs(:provides_format?).with(:'xml', anything).returns(true)
        about.expects(:render).with(:'xml', anything).returns("/about.xml")
        about.expects(:render).with(:'html', anything).never
        get "/about/@comments/page.xml"
        assert last_response.ok?
        last_response.body.should == "/about.xml"
      end

      should "use the format within the action if required" do
        get "/about/@comments/format.xml"
        assert last_response.ok?
        last_response.body.should == "xml"
      end

      should "be inherited by subclasses" do
        get "/about/now/@comments"
        assert last_response.ok?
        last_response.body.should == "Success"
      end

      should "allow definition of controller using class" do
        get "/about/@test"
        assert last_response.ok?
        last_response.body.should == "Magic"
      end

      should "allow definition of controller using class and extend it using block" do
        get "/about/@test2/block"
        assert last_response.ok?
        last_response.body.should == "Block"
      end

      context "overriding base controller class" do
        setup do
          class ::PageController < S::PageController
            get '/nothing' do
              'Something'
            end
          end

          SitePage.controller :drummer do
            get '/' do
              "Success"
            end
          end

        end

        teardown do
          Object.send(:remove_const, :PageController)
        end

        should "affect all controller actions" do
          get "/about/@drummer/nothing"
          assert last_response.ok?
          last_response.body.should == "Something"
        end
      end
    end
  end
end
