# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

ENV['RACK_ENV'] = 'test'

describe "Front" do
  include RackTestMethods

  start do
    site_root = Dir.mktmpdir
    FileUtils.cp_r(File.expand_path("../../fixtures/public/templates", __FILE__), site_root)
    Spontaneous::Output.write_compiled_scripts = true


    site = setup_site(site_root)
    let(:site) { site  }
    S::Site.background_mode = :immediate
    S::State.delete

    Site.background_mode = :immediate
    ::Content.delete

    class ::SitePage < ::Page
      layout :default
      layout :dynamic
      box :pages

      attr_accessor :status
    end

    class ::StaticPage < ::Page
      layout :default
    end
    class ::SubPage < SitePage; end


    root = ::SitePage.create
    about = ::SitePage.create(:slug => "about", :uid => "about")
    subpage = ::SubPage.create(:slug => "now", :uid => "now")
    news = ::SitePage.create(:slug => "news", :uid => "news")
    dynamic = ::SitePage.create(:slug => "dynamic", :uid => "dynamic")
    static  = ::StaticPage.create(:slug => "static", :uid => "static")
    dynamic.layout = :dynamic
    root.pages << about
    root.pages << news
    root.pages << dynamic
    root.pages << static
    about.pages << subpage
    root.save

    let(:root_id) { root.id }
    let(:about_id) { about.id }
    let(:subpage_id) { subpage.id }
    let(:news_id) { news.id }
    let(:dynamic_id) { dynamic.id }
    let(:static_id) { static.id }

    Content.delete_revision(1) rescue nil

    Spontaneous.logger.silent! {
      S::Site.publish_all
    }
  end

  finish do
    Object.send(:remove_const, :SitePage) rescue nil
    Object.send(:remove_const, :SubPage) rescue nil
    Content.delete
    S::State.delete
    Content.delete_revision(1)
    teardown_site(true)
    Spontaneous::Output.write_compiled_scripts = false
  end

  let(:root) { Content[root_id] }
  let(:about) { Content[about_id] }
  let(:subpage) { Content[subpage_id] }
  let(:news) { Content[news_id] }
  let(:dynamic) { Content[dynamic_id] }
  let(:static) { Content[static_id] }

  def app
    Spontaneous::Rack::Front.application
  end

  after do
    SitePage.instance_variable_set(:@layout_procs, nil)
    SitePage.instance_variable_set(:@request_blocks, {})
    [root, about, subpage, news, static].each do |page|
      page.layout = :default
    end
    dynamic.layout = :dynamic
  end

  def session
    last_request.env['rack.session']
  end

  def formats(format_list)
    format_list.map { |f| Page.format_for(f) }
  end

  describe "Public pages" do

    after do
      about.class.outputs :html
    end

    it "return a 404 if asked for a non-existant page" do
      get '/not-bloody-likely'
      assert last_response.status == 404
    end

    it "provide root when asked" do
      get '/'
      assert last_response.ok?
      last_response.body.must_equal "/.html\n"
    end

    it "be available through their path" do
      get '/about'
      assert last_response.ok?
      last_response.body.must_equal "/about.html\n"
      last_response.content_type.must_equal "text/html;charset=utf-8"
    end

    it "be available through their path with explicit format" do
      get '/about.html'
      assert last_response.ok?
      last_response.body.must_equal "/about.html\n"
      last_response.content_type.must_equal "text/html;charset=utf-8"
    end

    it "honor the format of the request" do
      about.class.outputs :html, :pdf
      get '/about.pdf'
      assert last_response.ok?
      last_response.body.must_equal "/about.pdf\n"
      last_response.content_type.must_equal "application/pdf;charset=utf-8"
    end

    it "provide the default format of the page if none is explicitly given" do
      about.class.outputs :rss, :html
      get '/about'
      assert last_response.ok?
      last_response.content_type.must_equal ::Rack::Mime.mime_type('.rss') + ";charset=utf-8"
      last_response.body.must_equal "/about.rss\n"
    end

    it "return a custom content type if one is defined" do
      about.class.outputs [:html, {:mimetype => "application/xhtml+xml"}]
      get '/about'
      assert last_response.ok?
      last_response.content_type.must_equal "application/xhtml+xml;charset=utf-8"
      last_response.body.must_equal "/about.html\n"
    end


    it "raise a 404 if asked for a format not provided by the page" do
      get '/about.time'
      assert last_response.status == 404
    end

    it "raise a 404 when accessing a private format" do
      about.class.outputs [:html, {:mimetype => "application/xhtml+xml"}], [:rss, {:private => true}]
      get '/about.rss'
      assert last_response.status == 404
    end

    describe "Dynamic pages" do
      before do
        Content::Page.stubs(:path).with("/about").returns(about)
        Content::Page.stubs(:path).with("/static").returns(static)
        Content::Page.stubs(:path).with("/news").returns(news)
      end

      after do
        about.layout = :default
        SitePage.instance_variable_set(:@request_blocks, {})
      end

      it "default to static behaviour" do
        refute SitePage.dynamic?
        page = SitePage.new
        refute page.dynamic?
      end
      it "correctly show a dynamic behaviour" do
        SitePage.request do
          show "/static"
        end
        assert SitePage.dynamic?
        page = SitePage.new
        assert page.dynamic?
      end

      it "render an alternate page if passed a page" do
        SitePage.request do
          show Site['/static']
        end
        get '/about'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "render an alternate page if passed a path" do
        # about.stubs(:request_show).returns("/news")
        SitePage.request do
          show "/static"
        end
        get '/about'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "render an alternate page if passed a uid with a #" do
        # about.stubs(:request_show).returns("#news")
        SitePage.request do
          show "static"
        end
        get '/about'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "render an alternate page if passed a uid" do
        # about.stubs(:request_show).returns("news")
        SitePage.request do
          show "static"
        end
        get '/about'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "return not found of #request_show returns an invalid uid or path" do
        # about.stubs(:request_show).returns("caterpillars")
        SitePage.request do
          show "caterpillars"
        end
        get '/about'
        assert last_response.status == 404
      end

      it "return the right status code" do
        SitePage.request do
          show "static", 404
        end
        get '/about'
        assert last_response.status == 404
        last_response.body.must_equal "/static.html\n"
      end

      it "allow handing POST requests" do
        SitePage.request :post do
          show "static"
        end
        post '/about'
        assert last_response.status == 200, "Expected status 200 but recieved #{last_response.status}"
        last_response.body.must_equal "/static.html\n"
      end

      it "allow returning of any status code without altering content" do
        SitePage.request do
          404
        end
        get '/about'
        assert last_response.status == 404
        last_response.body.must_equal "/about.html\n"
      end

      it "allow altering of headers" do
        SitePage.request do
          headers["X-Works"] = "Yes"
        end
        get '/about'
        assert last_response.status == 200
        last_response.body.must_equal "/about.html\n"
        last_response.headers["X-Works"].must_equal "Yes"
      end

      it "allow passing of template params & a page to the render call" do
        SitePage.layout do
          "{{ teeth }}"
        end
        SitePage.request do
          render page, :teeth => "white"
        end
        get '/about'
        assert last_response.status == 200
        last_response.body.must_equal "white"
        SitePage.instance_variable_set(:@layout_procs, nil)
      end

      it "give access to the request params within the controller" do
        SitePage.layout { "{{ params[:horse] }}*{{ equine }}" }
        SitePage.request :post do
          value = params[:horse]
          render page, :equine => value
        end
        post '/about', :horse => "dancing"
        assert last_response.status == 200
        last_response.body.must_equal "dancing*dancing"
        SitePage.instance_variable_set(:@layout_procs, nil)
      end

      it "allows for dynamically setting the output" do
        SitePage.add_output :mobile
        SitePage.layout do
          "${ path }.${ __format }"
        end
        SitePage.request :get do
          if request.user_agent =~ /iPhone/
            output :mobile
          end
        end
        get "/about", {}, { "HTTP_USER_AGENT" => "Desktop" }
        last_response.body.must_equal "/about.html"
        get "/about", {}, { "HTTP_USER_AGENT" => "iPhone" }
        last_response.body.must_equal "/about.mobile"
      end

      # should "handle anything that responds to #render(format)" do
      #   show = mock()
      #   show.stubs(:render).returns("mocked")
      #   about.stubs(:request_show).returns(show)
      #   get '/about'
      #   last_response.body.must_equal "mocked"
      # end
    end

    describe "Redirects" do
      before do
        Page.stubs(:path).with("/about").returns(about)
        Page.stubs(:path).with("/news").returns(news)
      end

      it "respond appropriatly to redirects to path" do
        SitePage.request do
          redirect "/news"
        end
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "respond appropriately to redirects to a Page instance" do
        SitePage.request do
          redirect Page.path("/news")
        end
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "respond appropriately to redirects to a UID" do
        SitePage.request do
          redirect "news"
        end
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "recognise a :temporary redirect" do
        SitePage.request do
          redirect "/news", :temporary
        end
        get '/about'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "recognise a :permanent redirect" do
        SitePage.request do
          redirect "/news", :permanent
        end
        get '/about'
        assert last_response.status == 301
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "correctly apply numeric status codes" do
        SitePage.request do
          redirect "/news", 307
        end
        get '/about'
        last_response.headers["Location"].must_equal "http://example.org/news"
        assert last_response.status == 307
      end

    end

    describe "Templates" do
      before do
        Spontaneous::Output.cache_templates = true
        @cache_file = "#{Spontaneous.revision_dir(1)}/dynamic/dynamic.html.rb"
        FileUtils.rm(@cache_file) if File.exist?(@cache_file)
        Spontaneous::Output.write_compiled_scripts = true
      end

      after do
        Spontaneous::Output.cache_templates = true
      end

      it "have access to the params, request & session object" do
        get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        assert last_response.ok?
        last_response.body.must_equal "42/peter/example.org\n"
      end

      describe "caching" do
        it "use pre-rendered versions of the templates" do
          dummy_content = 'cached-version/#{session[\'user_id\']}'
          dummy_template = File.join(site.revision_root, "current/dynamic/dynamic.html.cut")
          File.open(dummy_template, 'w') { |f| f.write(dummy_content) }
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          last_response.body.must_equal "cached-version/42"
        end

        it "cache templates as ruby files" do
          dummy_content = 'cached-version/#{session[\'user_id\']}'
          dummy_template = File.join(site.revision_root, "current/dynamic/index.html.cut")
          Spontaneous::Output.renderer.write_compiled_scripts = true
          File.open(dummy_template, 'w') { |f| f.write(dummy_content) }
          FileUtils.rm(@cache_file) if File.exists?(@cache_file)
          refute File.exists?(@cache_file)
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }

          assert File.exists?(@cache_file)
          File.open(@cache_file, 'w') { |f| f.write('@__buf << %Q`@cache_filed-version/#{params[\'wendy\']}`;')}
          # Force compiled file to have a later timestamp
          File.utime(Time.now, Time.now + 1, @cache_file)
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          last_response.body.must_equal "@cache_filed-version/peter"
        end

        it "not cache templates if caching turned off" do
          Spontaneous::Output.cache_templates = false
          refute File.exists?(@cache_file)
          get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
          refute File.exists?(@cache_file)
        end
      end
    end

    describe "Model controllers" do
      before do
        SitePage.instance_variable_set(:@request_blocks, {})
        class ::TestController < Spontaneous::Rack::PageController
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

        Content.stubs(:path).with("/").returns(root)
        Content.stubs(:path).with("/about").returns(about)
        Content.stubs(:path).with("/about/now").returns(subpage)
      end

      after do
        SitePage.instance_variable_set(:@request_blocks, {})
        SitePage.send(:remove_const, :StatusController) rescue nil
        SitePage.send(:remove_const, :TestController) rescue nil
        SitePage.send(:remove_const, :Test2Controller) rescue nil
        Object.send(:remove_const, :TestController) rescue nil
        about.class.outputs :html
      end

      it "not be used unless necessary" do
        get "/about"
        assert last_response.ok?
        last_response.body.must_equal about.render
      end

      it "work on the homepage" do
        get "/@comments"
        assert last_response.ok?
        last_response.body.must_equal "Success"
      end


      it "be recognised" do
        get "/about/@comments"
        assert last_response.ok?
        last_response.body.must_equal "Success"
      end

      it "render the page correctly if action returns page object" do
        get "/about/@comments/page"
        assert last_response.ok?
        last_response.body.must_equal about.render
      end

      it "return 404 if trying unknown namespace" do
        get "/about/@missing/action"
        assert last_response.status == 404
      end

      it "respond to multiple namespaces" do
        get "/about/@status/good"
        assert last_response.ok?
        last_response.body.must_equal about.render
        about.status.must_equal "good"
      end

      it "accept POST requests" do
        post "/about/@status/good"
        assert last_response.ok?
        last_response.body.must_equal about.render
        about.status.must_equal "good"
      end

      it "return 404 unless post request has an action" do
        Page.expects(:path).with("/about").never
        post "/about"
        assert last_response.status == 404
      end

      it "return 404 for post requests to unknown actions" do
        post "/about/@status/missing/action"
        assert last_response.status == 404
      end

      # probably the wrong place to test this -- should be in units -- but what the heck
      it "be able to generate urls for actions" do
        about.action_url(:status, "/good").must_equal "/about/@status/good"
      end

      it "pass the format onto the page if the action returns it to the render call" do
        about.class.outputs :html, :xml
        about.class.layout do
          "${path}.${__format}"
        end
        get "/about/@comments/page.xml"
        assert last_response.ok?
        last_response.body.must_equal "/about.xml"
      end

      it "use the format within the action if required" do
        about.class.outputs :html, :xml
        get "/about/@comments/format.xml"
        assert last_response.ok?
        last_response.body.must_equal "xml"
      end

      it "be inherited by subclasses" do
        get "/about/now/@comments"
        assert last_response.ok?
        last_response.body.must_equal "Success"
      end

      it "allow definition of controller using class" do
        get "/about/@test"
        assert last_response.ok?
        last_response.body.must_equal "Magic"
      end

      it "allow definition of controller using class and extend it using block" do
        get "/about/@test2/block"
        assert last_response.ok?
        last_response.body.must_equal "Block"
      end

      describe "overriding base controller class" do
        before do
          class ::PageController < S::Rack::PageController
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

        after do
          Object.send(:remove_const, :PageController)
        end

        it "affect all controller actions" do
          get "/about/@drummer/nothing"
          assert last_response.ok?
          last_response.body.must_equal "Something"
        end
      end
    end

    describe "Static files" do
      before do
        @revision_dir = Spontaneous.instance.revision_dir(1)
        @public_dir = @revision_dir / "public"
      end

      it "should be sourced from the published revision directory" do
        test_string = "#{Time.now}\n"
        test_file = "#{Time.now.to_i}.txt"
        File.open(@public_dir / test_file, 'w') { |f| f.write(test_string) }
        get "/#{test_file}"
        assert last_response.ok?
        last_response.body.must_equal test_string
      end

      it "pass far-future expires headers for media" do
        test_string = "#{Time.now}\n"
        test_file_url = "#{Time.now.to_i}.txt"
        test_file = Spontaneous.media_dir / test_file_url
        FileUtils.mkdir_p(File.dirname(test_file))
        File.open(test_file, 'w') { |f| f.write(test_string) }
        get "/media/#{test_file_url}"
        assert last_response.ok?
        last_response.body.must_equal test_string
        expiry = DateTime.parse last_response.headers["Expires"]
        expiry.year.must_equal (Date.today.year) + 10
      end

      it "pass far-future expires headers for compiled assets" do
        test_string = "#{Time.now}\n"
        test_file_url = "/rev/#{Time.now.to_i}.txt"
        test_file = @revision_dir / test_file_url
        FileUtils.mkdir_p(File.dirname(test_file))
        File.open(test_file, 'w') { |f| f.write(test_string) }
        get test_file_url
        assert last_response.ok?
        last_response.body.must_equal test_string
        expiry = DateTime.parse last_response.headers["Expires"]
        expiry.year.must_equal (Date.today.year) + 10
      end
    end
  end
end