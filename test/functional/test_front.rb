# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

ENV['RACK_ENV'] = 'test'

describe "Front" do
  include RackTestMethods

  start do
    @warn_level = $VERBOSE
    $VERBOSE = nil
    site_root = Dir.mktmpdir
    FileUtils.cp_r(File.expand_path("../../fixtures/public/templates", __FILE__), site_root)
    Spontaneous::Output.write_compiled_scripts = true


    class ::PageController < S::Rack::PageController
      # Define a per-site base controller for all controller classes here so
      # that we can test it's use later on.
      # If I define it only in the test where it's used then it's too late as
      # the controller hierarchy will have already been built upon some other
      # base class.
      #
      # (Another argument for replacing these [start..finish] blocks with
      # [before..after] ones)
    end

    site = setup_site(site_root)
    let(:site) { site  }
    S::State.delete

    site.background_mode = :immediate
    site.output_store :Memory
    ::Content.delete

    class ::Page
      controller do
        set :show_exceptions, false
        set :raise_errors, true
        set :dump_errors, true
      end
    end
    class ::SitePage < ::Page
      add_output :pdf
      layout :default
      layout :dynamic
      box :pages

      attr_accessor :status
    end

    class ::StaticPage < ::Page
      layout :default
    end

    class ::DynamicRequestParams < ::Page
      singleton
      layout(:html) { "{{ params[:horse] }}*{{ equine }}" }
    end

    class ::DynamicRenderParams < ::Page
      singleton
      add_output :mobile
      add_output :session
      add_output :params
      layout(:html) { "{{ teeth }}${ path }.${ __format }" }
      layout(:mobile) { "${ path }.${ __format }" }
      layout(:session) { %[{{session['user_id']}}/{{params['wendy']}}/{{request.env["SERVER_NAME"]}}] }
      layout(:params) { "{{ something }}"}
    end

    class ::CommentablePage < ::Page
      attr_accessor :status

      add_output :xml
      add_output :post
      layout(:html) { "${path}.${ __format }" }
      layout(:post) { "{{results.join(',')}}" }
      layout(:xml) { "${ path}.${ __format }" }
      box :pages
    end

    class ::FeedPage < ::Page
      outputs :rss, [:html, {:mimetype => "application/xhtml+xml"}], [:pdf, {:private => true}]
      layout { "${ path }.${ __format }" }
    end

    class ::TakeItPage < ::Page
      layout(:html) { "take it ${id} {{ splat }}" }
      box :pages
    end

    root = ::SitePage.create
    about = ::SitePage.create(:slug => "about", :uid => "about")
    feed = ::FeedPage.create(:slug => "feed", :uid => "feed")
    news = ::SitePage.create(:slug => "news", :uid => "news")
    static  = ::StaticPage.create(:slug => "static", :uid => "static")
    dynamic_request_params = ::DynamicRequestParams.create(slug: "dynamic-request-params", uid: "dynamic_request_params")
    dynamic_render_params = ::DynamicRenderParams.create(slug: "dynamic-render-params", uid: "dynamic_render_params")
    commentable = ::CommentablePage.create(slug:"commentable", uid: "commentable")
    take_it =  TakeItPage.create(slug: 'takeit', uid: 'takeit')
    take_it_again =  TakeItPage.create(slug: 'again', uid: 'again')
    root.pages << about
    root.pages << feed
    root.pages << news
    root.pages << dynamic_request_params
    root.pages << dynamic_render_params
    root.pages << static
    root.pages << commentable
    root.pages << take_it
    take_it.pages << take_it_again
    root.save
    take_it.save

    let(:root_id) { root.id }
    let(:about_id) { about.id }
    let(:feed_id) { feed.id }
    let(:news_id) { news.id }
    let(:take_it_id) { take_it.id }
    let(:take_it_again_id) { take_it_again.id }
    let(:dynamic_request_params_id) { dynamic_request_params.id }
    let(:dynamic_render_params_id) { dynamic_render_params.id }
    let(:static_id) { static.id }
    let(:commentable_id) { commentable.id }

    Content.delete_revision(1) rescue nil

    site.publish_steps = Spontaneous::Publishing::Steps.default

    Spontaneous.logger.silent! {
      site.publish_all
    }
  end

  finish do
    [:SitePage, :StaticPage, :DynamicRequestParams, :DynamicRenderParams, :CommentablePage, :FeedPage, :TakeItPage, :PageController].each do |const|
      Object.send(:remove_const, const) rescue nil
    end
    if defined?(Content)
      Content.delete
      Content.delete_revision(1)
    end
    S::State.delete
    teardown_site(true)
    Spontaneous::Output.write_compiled_scripts = false
    $VERBOSE = @warn_level
  end

  let(:root) { Content[root_id] }
  let(:about) { Content[about_id] }
  let(:feed) { Content[feed_id] }
  let(:news) { Content[news_id] }
  let(:take_it) { Content[take_it_id] }
  let(:take_it_again) { Content[take_it_again_id] }
  let(:dynamic_request_params) { Content[dynamic_request_params_id] }
  let(:dynamic_render_params) { Content[dynamic_render_params_id] }
  let(:static) { Content[static_id] }
  let(:commentable) { Content[commentable_id] }

  def app
    @app ||= Spontaneous::Rack::Front.application(site)
  end

  def renderer
    @renderer ||= Spontaneous::Output::Template::PublishRenderer.new(site, true)
  end

  def session
    last_request.env['rack.session']
  end

  def formats(format_list)
    format_list.map { |f| Page.format_for(f) }
  end

  describe "Public pages" do

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
      get '/about.pdf'
      assert last_response.ok?
      last_response.body.must_equal "/about.pdf\n"
      last_response.content_type.must_equal "application/pdf;charset=utf-8"
    end

    it "provide the default format of the page if none is explicitly given" do
      get '/feed'
      assert last_response.ok?
      last_response.content_type.must_equal ::Rack::Mime.mime_type('.rss') + ";charset=utf-8"
      last_response.body.must_equal "/feed.rss"
    end

    it "return a custom content type if one is defined" do
      get '/feed.html'
      assert last_response.ok?
      last_response.content_type.must_equal "application/xhtml+xml;charset=utf-8"
      last_response.body.must_equal "/feed.html"
    end


    it "raise a 404 if asked for a format not provided by the page" do
      get '/about.time'
      assert last_response.status == 404
    end

    it "raise a 404 when accessing a private format" do
      get '/feed.pdf'
      assert last_response.status == 404
    end

    describe "Dynamic pages" do
      before do
        Content::Page.stubs(:path).with("/").returns(root)
        Content::Page.stubs(:path).with("/about").returns(about)
        Content::Page.stubs(:path).with("/static").returns(static)
        Content::Page.stubs(:path).with("/news").returns(news)
      end

      after do
      end

      it "default to static behaviour" do
        refute SitePage.dynamic?
        page = SitePage.new
        refute page.dynamic?
      end

      it "correctly show a dynamic behaviour" do
        DynamicRenderParams.controller do
          get { show "/static" }
        end
        assert DynamicRenderParams.dynamic?
        page = DynamicRenderParams.new
        assert page.dynamic?
      end

      it "render an alternate page if passed a page" do
        DynamicRenderParams.controller do
          get { render site['/static'] }
        end
        get '/dynamic-render-params'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "render an alternate page if passed a path" do
        DynamicRenderParams.controller do
          get { render "/static" }
        end
        get '/dynamic-render-params'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "render an alternate page if passed a uid with a #" do
        DynamicRenderParams.controller do
          get { render "static" }
        end
        get '/dynamic-render-params'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "render an alternate page if passed a uid" do
        DynamicRenderParams.controller do
          get { render "static" }
        end
        get '/dynamic-render-params'
        assert last_response.ok?
        last_response.body.must_equal "/static.html\n"
      end

      it "return not found of #request_show returns an invalid uid or path" do
        DynamicRenderParams.controller do
          get { render "caterpillars" }
        end
        get '/dynamic-render-params'
        assert last_response.status == 404, "Expected 404 but got #{last_response.status}"
      end

      it "return the right status code" do
        DynamicRenderParams.controller do
          get { render "static", 403 }
        end
        get '/dynamic-render-params'
        assert last_response.status == 403
        last_response.body.must_equal "/static.html\n"
      end

      it "allow handing POST requests" do
        DynamicRenderParams.controller do
          post { render "static" }
        end
        post '/dynamic-render-params'
        assert last_response.status == 200, "Expected status 200 but recieved #{last_response.status}"
        last_response.body.must_equal "/static.html\n"
      end

      it "allow returning of any status code without altering content" do
        DynamicRenderParams.controller do
          get { render 403 }
        end
        get '/dynamic-render-params'
        assert last_response.status == 403
        last_response.body.must_equal "/dynamic-render-params.html"
      end

      it "allow altering of headers" do
        DynamicRenderParams.controller do
          get do
            headers["X-Works"] = "Yes"
            render
          end
        end
        get '/dynamic-render-params'
        assert last_response.status == 200
        last_response.body.must_equal "/dynamic-render-params.html"
        last_response.headers["X-Works"].must_equal "Yes"
      end

      it "allow passing of template params & a page to the render call" do
        DynamicRenderParams.controller do
          get { render page, :teeth => "blue" }
        end
        get '/dynamic-render-params'
        assert last_response.status == 200
        last_response.body.must_equal "blue/dynamic-render-params.html"
      end

      it "allows setting status code and passing parameters to the show call" do
        DynamicRenderParams.controller do
          get { render DynamicRenderParams, 401, :teeth => "white" }
        end
        get '/dynamic-render-params'
        assert last_response.status == 401
        last_response.body.must_equal "white/dynamic-render-params.html"
      end

      it "allows passing parameters to the render call" do
        DynamicRenderParams.controller do
          get { render DynamicRenderParams, :teeth => "white" }
        end
        get '/dynamic-render-params'
        assert last_response.status == 200
        last_response.body.must_equal "white/dynamic-render-params.html"
      end

      it "give access to the request params within the controller" do
        DynamicRequestParams.controller do
          post do
            value = params[:horse]
            render page, :equine => value
          end
        end
        post '/dynamic-request-params', :horse => "dancing"
        assert last_response.status == 200
        last_response.body.must_equal "dancing*dancing"
      end

      it "allows for dynamically setting the output" do
        DynamicRenderParams.controller do
          get do
            if request.user_agent =~ /iPhone/
              output :mobile
            end
            render teeth: "clean"
          end
        end
        get "/dynamic-render-params", {}, { "HTTP_USER_AGENT" => "Desktop" }
        assert last_response.status == 200, "Expected status 200 but got #{last_response.status}"
        last_response.body.must_equal "clean/dynamic-render-params.html"
        get "/dynamic-render-params", {}, { "HTTP_USER_AGENT" => "iPhone" }
        last_response.body.must_equal "/dynamic-render-params.mobile"
      end

      it "inherits any request handlers from superclasses" do
        # request block inheritance is done at type creation & is not dynamic
        # so we need to create a new class that will inherit the newly minted
        # :get request handler
        DynamicRenderParams.controller do
          get { render "about" }
        end

        class ::TempPage < DynamicRenderParams; end

        temp = ::TempPage.create(:slug => "temp", :uid => "temp")
        root.pages << temp
        root.save
        site.model.stubs(:path).with("/temp").returns(temp)

        get "/temp"
        last_response.status.must_equal 200
        last_response.body.must_equal "/about.html\n"

        temp.destroy
        Object.send(:remove_const, "TempPage")
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
        DynamicRenderParams.controller do
          get do
            redirect "/news"
          end
        end
        get '/dynamic-render-params'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "respond appropriately to redirects to a Page instance" do
        DynamicRenderParams.controller do
          get { redirect Page.path("/news") }
        end
        get '/dynamic-render-params'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "respond appropriately to redirects to a UID" do
        DynamicRenderParams.controller do
          get { redirect "news" }
        end
        get '/dynamic-render-params'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "recognise a :temporary redirect" do
        DynamicRenderParams.controller do
          get { redirect "/news", :temporary }
        end
        get '/dynamic-render-params'
        assert last_response.status == 302
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "recognise a :permanent redirect" do
        DynamicRenderParams.controller do
          get { redirect "/news", :permanent }
        end
        get '/dynamic-render-params'
        assert last_response.status == 301
        last_response.headers["Location"].must_equal "http://example.org/news"
      end

      it "correctly apply numeric status codes" do
        DynamicRenderParams.controller do
          get { redirect "/news", 307 }
        end
        get '/dynamic-render-params'
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
        DynamicRenderParams.controller do
          get { render }
        end
        get '/dynamic-render-params.session', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        assert last_response.ok?, "Expected status 200 but got #{last_response.status}"
        last_response.body.must_equal "42/peter/example.org"
      end

      # Disabled for the moment while I think about the implications of the
      # template store & if there isn't a better way to optimise the render
      # by using a LRU cache of the compiled classes or something like that.
      describe "caching" do
        # it "use pre-rendered versions of the templates" do
        #   dummy_content = 'cached-version/#{session[\'user_id\']}'
        #   dummy_template = File.join(site.revision_root, "current/dynamic/dynamic.html.cut")
        #   File.open(dummy_template, 'w') { |f| f.write(dummy_content) }
        #   get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        #   last_response.body.must_equal "cached-version/42"
        # end

        # it "cache templates as ruby files" do
        #   dummy_content = 'cached-version/#{session[\'user_id\']}'
        #   dummy_template = File.join(site.revision_root, "current/dynamic/index.html.cut")
        #   # Spontaneous::Output.renderer.write_compiled_scripts = true
        #   File.open(dummy_template, 'w') { |f| f.write(dummy_content) }
        #   FileUtils.rm(@cache_file) if File.exists?(@cache_file)
        #   refute File.exists?(@cache_file)
        #   get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }

        #   assert File.exists?(@cache_file)
        #   File.open(@cache_file, 'w') { |f| f.write('@__buf << %Q`@cache_filed-version/#{params[\'wendy\']}`;')}
        #   # Force compiled file to have a later timestamp
        #   File.utime(Time.now, Time.now + 1, @cache_file)
        #   get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        #   last_response.body.must_equal "@cache_filed-version/peter"
        # end

        # it "not cache templates if caching turned off" do
        #   Spontaneous::Output.cache_templates = false
        #   refute File.exists?(@cache_file)
        #   get '/dynamic', {'wendy' => 'peter'}, 'rack.session' => { 'user_id' => 42 }
        #   refute File.exists?(@cache_file)
        # end
      end
    end

    describe "Model controllers" do
      before do
        class ::TestController < Spontaneous::Rack::PageController
          get '/' do
            "Magic"
          end
        end
        CommentablePage.controller :comments do
          get '/' do
            "Success"
          end

          get '/page' do
            page
          end
          get '/format' do
            output.to_s
          end
        end

        CommentablePage.controller :status do
          get '/:status' do
            page.status = params[:status]
            page
          end

          post '/:status' do
            page.status = params[:status]
            page
          end
        end

        CommentablePage.controller :search do
          get '/render/:query' do
            render({ results: %w(a b c)})
          end

          get '/renderpapeparams/:query' do
            render page, { results: %w(a b c)}
          end

          get '/renderoutput/:query' do
            render page, :post, { results: %w(a b c)}
          end
        end

        CommentablePage.controller :test, ::TestController

        CommentablePage.controller :test2, ::TestController do
          get "/block" do
            "Block"
          end
        end

        class ::SubPage < CommentablePage; end
        @subpage = ::SubPage.create(:slug => "now", :uid => "now")
        commentable.pages << @subpage

        @subpage.reload

        Content.stubs(:path).with("/").returns(root)
        Content.stubs(:path).with("/commentable").returns(commentable)
        Content.stubs(:path).with("/commentable/now").returns(@subpage)
        @renderer = Spontaneous::Output.published_renderer(site)
      end

      after do
        Object.send(:remove_const, :SubPage) rescue nil
        CommentablePage.instance_variable_set(:@controllers, nil)
        CommentablePage.send(:remove_const, :StatusController) rescue nil
        CommentablePage.send(:remove_const, :TestController) rescue nil
        CommentablePage.send(:remove_const, :Test2Controller) rescue nil
        Object.send(:remove_const, :TestController) rescue nil
      end

      it "not be used unless necessary" do
        get "/commentable"
        assert last_response.ok?
        last_response.body.must_equal commentable.render_using(@renderer).read
      end

      it "work on sub classes" do
        get "/commentable/now/@comments"
        assert last_response.ok?
        last_response.body.must_equal "Success"
      end


      it "be recognised" do
        get "/commentable/@comments"
        assert last_response.ok?
        last_response.body.must_equal "Success"
      end

      it "render the page correctly if action returns page object" do
        get "/commentable/@comments/page"
        assert last_response.ok?
        last_response.body.must_equal commentable.render_using(@renderer).read
      end

      it "return 404 if trying unknown namespace" do
        get "/commentable/@missing/action"
        assert last_response.status == 404
      end

      it "respond to multiple namespaces" do
        get "/commentable/@status/good"
        assert last_response.ok?
        last_response.body.must_equal commentable.render_using(@renderer).read
        commentable.status.must_equal "good"
      end

      it "accept POST requests" do
        post "/commentable/@status/good"
        assert last_response.ok?
        last_response.body.must_equal commentable.render_using(@renderer).read
        commentable.status.must_equal "good"
      end

      it "return 404 unless post request has an action" do
        Page.expects(:path).with("/commentable").never
        post "/commentable"
        assert last_response.status == 404
      end

      it "return 404 for post requests to unknown actions" do
        post "/commentable/@status/missing/action"
        assert last_response.status == 404
      end

      # probably the wrong place to test this -- should be in units -- but what the heck
      it "be able to generate urls for actions" do
        commentable.action_url(:status, "/good").must_equal "/commentable/@status/good"
      end

      it "be able to generate urls for actions with no path" do
        commentable.action_url(:status).must_equal "/commentable/@status"
      end

      it "pass the output onto the page if the action returns it to the render call" do
        get "/commentable/@comments/page.xml"
        assert last_response.ok?
        last_response.body.must_equal "/commentable.xml"
      end

      it "use the format within the action if required" do
        get "/commentable/@comments/format.xml"
        assert last_response.ok?, "Expected status 200 but got #{last_response.status}"
        last_response.body.must_equal "xml"
      end

      it "be inherited by subclasses" do
        get "/commentable/now/@comments"
        assert last_response.ok?
        last_response.body.must_equal "Success"
      end

      it "allow definition of controller using class" do
        get "/commentable/@test"
        assert last_response.ok?
        last_response.body.must_equal "Magic"
      end

      it "allow definition of controller using class and extend it using block" do
        get "/commentable/@test2/block"
        assert last_response.ok?
        last_response.body.must_equal "Block"
      end

      it "allows passing parameters to the page render" do
        get "/commentable/@search/render/query.post"
        assert last_response.ok?, "Expected 200 OK but got #{last_response.status}"
        last_response.body.must_equal "a,b,c"
      end

      it "allows passing an output to the page render" do
        get "/commentable/@search/renderoutput/query"
        assert last_response.ok?, "Expected 200 OK but got #{last_response.status}"
        last_response.body.must_equal "a,b,c"
      end

      describe "overriding base controller class" do
        before do
          ::PageController.get '/nothing' do
            'Something'
          end

          CommentablePage.controller :drummer do
            get '/' do
              "Success"
            end
          end
        end

        it "affect all controller actions" do
          get "/commentable/@drummer/nothing"
          assert last_response.ok?, "Expected 200 got #{last_response.status}"
          last_response.body.must_equal "Something"
        end
      end
    end

    describe 'wildcard paths' do
      let(:page) { take_it }
      let(:again) { take_it_again }

      after do
        root.class.instance_variable_set(:@controllers, nil)
        TakeItPage.instance_variable_set(:@controllers, nil)
      end

      it 'renders a url that resolves to a page accepting the path' do
        TakeItPage.controller do
          get '*' do
            render splat: params[:splat].first
          end
        end
        [
          ["/something", page],
          ["/something/else", page],
          ["/really/something/else/entirely", page],
          ["/something/else/entirely", again]
        ].each do |path, expected|
          get "#{expected.path}#{path}"
          assert last_response.ok?, "Expected 200 got #{last_response.status}"
          last_response.body.must_equal "take it #{expected.id} #{path}"
        end
      end

      it 'returns 404 if the requested path doesn’t match the controller’s route' do
        TakeItPage.controller do
          get '/womble/?:where?' do
            render splat: params[:where]
          end
        end
        get "#{page.path}/womble/around"
        assert last_response.ok?, "Expected 200 got #{last_response.status}"
        last_response.body.must_equal "take it #{page.id} around"

        get "#{page.path}/womble"
        assert last_response.ok?, "Expected 200 got #{last_response.status}"
        last_response.body.must_equal "take it #{page.id} "

        get "#{page.path}/wimble/around"
        assert last_response.status == 404
      end

      it 'returns 404 if the controller is only configured to match the root' do
        TakeItPage.controller do
          get do
            render splat: 'root'
          end
        end
        get page.path
        assert last_response.ok?, "Expected 200 got #{last_response.status}"
        last_response.body.must_equal "take it #{page.id} root"

        get "#{page.path}/womble"
        assert last_response.status == 404, "Expected 404 but got #{last_response.status}"
      end

      it 'can fall back to controllers defined on the site homepage' do
        root.class.controller do
          get '/' do
            "ow"
          end
          get '/slimy/:who' do
            "<#{params[:who]}>"
          end
        end

        get '/slimy/monster'
        assert last_response.ok?, "Expected 200 got #{last_response.status}"
        last_response.body.must_equal "<monster>"

        get '/'
        assert last_response.ok?, "Expected 200 got #{last_response.status}"
        last_response.body.must_equal "ow"
      end
    end

    describe "Static files" do
      before do
        @revision_dir = Spontaneous.instance.revision_dir(1)
        @public_dir = @revision_dir / "public"
      end

      it "should be sourced from the published revision directory" do
        test_string = "#{Time.now}\n"
        test_file_path = "/#{Time.now.to_i}.txt"
        test_file_url = test_file_path
        site.output_store.revision(1).transaction.store_static(test_file_path, test_string)
        get test_file_url
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
        expiry.year.must_equal (Date.today.year) + 1
      end

      it "pass far-future expires headers for compiled assets" do
        test_string = "#{Time.now}\n"
        test_file_path = "/#{Time.now.to_i}.txt"
        test_file_url = "/assets#{test_file_path}"
        site.output_store.revision(1).transaction.store_asset(test_file_path, test_string)
        get test_file_url
        assert last_response.ok?
        last_response.body.must_equal test_string
        expiry = DateTime.parse last_response.headers["Expires"]
        expiry.year.must_equal (Date.today.year) + 1
      end
    end
  end
end
