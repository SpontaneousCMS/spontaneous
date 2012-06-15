# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# set :environment, :test


class BackTest < MiniTest::Spec
  include ::Rack::Test::Methods


  def self.site_root
    @site_root
  end

  def self.startup
    @site_root = Dir.mktmpdir
    app_root = File.expand_path('../../fixtures/back', __FILE__)
    FileUtils.cp_r(app_root, @site_root)
    @site_root += "/back"
    FileUtils.mkdir_p(@site_root / "cache")
    FileUtils.cp_r(File.join(File.dirname(__FILE__), "../fixtures/media"), @site_root / "cache")
  end

  def self.shutdown
    teardown_site
  end

  def app
    Spontaneous::Rack::Back.application
  end

  def setup
    @site = setup_site(self.class.site_root)
    Spot::Permissions::UserLevel.reset!
    Spot::Permissions::UserLevel.init!
  end


  def auth_post(path, params={}, env={})
    post(path, params.merge("__key" => @key), env)
  end

  def auth_get(path, params={}, env={})
    get(path, params.merge("__key" => @key), env)
  end

  context "Editing interface" do
    setup do
      @storage = @site.default_storage
      @site.stubs(:storage).with(anything).returns(@storage)
      config = mock()
      config.stubs(:reload_classes).returns(false)
      config.stubs(:auto_login).returns('root')
      config.stubs(:default_charset).returns('utf-8')
      config.stubs(:publishing_method).returns(:immediate)
      config.stubs(:services).returns(nil)
      config.stubs(:site_domain).returns('example.org')
      config.stubs(:site_id).returns('example_org')
      config.stubs(:site_id).returns('example_org')
      @site.stubs(:config).returns(config)

      S::Rack::Back::EditingInterface.set :raise_errors, true
      S::Rack::Back::EditingInterface.set :dump_errors, true
      S::Rack::Back::EditingInterface.set :show_exceptions, false

      Content.delete
      Spontaneous::Permissions::User.delete
      self.template_root = File.expand_path('../../fixtures/back/templates', __FILE__)
      @app_dir = File.expand_path("../../fixtures/application", __FILE__)
      File.exists?(@app_dir).should be_true
      Spontaneous.stubs(:application_dir).returns(@app_dir)
      # Spontaneous::Rack::Back.application.send :set, :show_exceptions, false

      # annoying to have to do this, but there you go
      @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root name", :password => "rootpass", :password_confirmation => "rootpass")
      @user.update(:level => Spontaneous::Permissions[:editor])
      @user.save
      @key = "c5AMX3r5kMHX2z9a5ExLKjAmCcnT6PFf22YQxzb4Codj"
      @key.stubs(:user).returns(@user)
      @key.stubs(:key_id).returns(@key)
      @user.stubs(:access_keys).returns([@key])

      Spontaneous::Permissions::User.stubs(:[]).with(:login => 'root').returns(@user)
      Spontaneous::Permissions::User.stubs(:[]).with(@user.id).returns(@user)
      Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(@key).returns(@key)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(@key, @user).returns(true)

      class Page < Spot::Page
        field :title
      end

      class Piece < Spot::Piece; end
      class Project < Page; end
      class Image < Piece
        field :image, :image
      end

      class Job < Piece
        field :title
        field :image, :image

        box :images do
          field :title
          field :image
          allow Image
        end
      end

      class LinkedJob < Piece
        alias_of proc { |owner, box| box.contents }
      end

      class HomePage < Page
        field :introduction, :text
        box :projects do
          allow Project
        end
        box :in_progress do
          allow Job
          allow Image
        end

        box :featured_jobs do
          allow LinkedJob
        end
      end

      class AdminAccess < Page
        field :title
        field :private, :user_level => :root
      end


      @home = HomePage.new(:title => "Home")
      @project1 = Project.new(:title => "Project 1", :slug => "project1")
      @project2 = Project.new(:title => "Project 2", :slug => "project2")
      @project3 = Project.new(:title => "Project 3", :slug => "project3")
      @home.projects << @project1
      @home.projects << @project2
      @home.projects << @project3

      @job1 = Job.new(:title => "Job 1", :image => "/i/job1.jpg")
      @job2 = Job.new(:title => "Job 2", :image => "/i/job2.jpg")
      @job3 = Job.new(:title => "Job 3", :image => "/i/job3.jpg")
      @image1 = Image.new
      @job1.images << @image1
      @home.in_progress << @job1
      @home.in_progress << @job2
      @home.in_progress << @job3


      @home.save
      @home = Content[@home.id]

    end

    teardown do
      [:Page, :Piece, :HomePage, :Job, :Project, :Image, :LinkedJob, :AdminAccess].each { |klass| BackTest.send(:remove_const, klass) rescue nil }
      Spontaneous::Permissions::User.delete
      Content.delete
    end

    context "@spontaneous" do
      setup do
        Spontaneous.stubs(:reload!)
      end

      should "return application page" do
        get '/@spontaneous/'
        assert last_response.ok?, "Should have returned 200 but got #{last_response.status}"
        last_response.body.should =~ /<title>Spontaneous/
      end

      should "return json for root page" do
        auth_get '/@spontaneous/root'
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal S::JSON.encode(Site.root.export), last_response.body
      end

      should "return json for individual pages" do
        page = Site.root.children.first
        auth_get "/@spontaneous/page/#{page.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal S::JSON.encode(page.export), last_response.body
      end

      should "respect user levels in page json" do
        page = AdminAccess.create
        auth_get "/@spontaneous/page/#{page.id}"
        result = Spot::JSON.parse(last_response.body)
        result[:fields].map { |f| f[:name] }.should == ["title"]
      end

      should "return the typelist as part of the site metadata xxx" do
        auth_get "/@spontaneous/metadata"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        last_response.content_type.should == "application/json;charset=utf-8"
        result = Spot::JSON.parse(last_response.body)
        result[:types].stringify_keys.should == Site.schema.export(@user)
      end

      should "apply the current user's permissions to the exported schema" do
        auth_get "/@spontaneous/metadata"
        assert last_response.ok?
        result = Spot::JSON.parse(last_response.body)
        result[:types][:'BackTest.AdminAccess'][:fields].map { |f| f[:name] }.should == %w(title)
      end

      should "return info about the current user in the metadata" do
        auth_get "/@spontaneous/metadata"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        result[:user][:email].should == "root@example.com"
        result[:user][:login].should == "root"
        result[:user][:name].should  == "root name"
        result[:user][:developer].should  == false # although the login is root, the level is :editor
      end

      should "return an empty list of service URLs by default xxx" do
        auth_get "/@spontaneous/metadata"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        result[:services].should == []
      end

      should "return the configured list of service URLs in the metadata xxx" do
        Site.config.stubs(:services).returns([
          {:title => "Google Analytics", :url => "http://google.com/analytics"},
          {:title => "Facebook", :url => "http://facebook.com/spontaneous"}
        ])
        auth_get "/@spontaneous/metadata"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        result[:services].should == Site.config.services
      end

      should "return scripts from js dir" do
        get '/@spontaneous/js/test.js'
        assert last_response.ok?
        # last_response.content_type.should == "application/javascript;charset=utf-8"
        last_response.content_type.should == "application/javascript"
        assert_equal File.read(@app_dir / 'js/test.js'), last_response.body
      end

      should "return a site map for root by default" do
        auth_get '/@spontaneous/map'
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.map.to_json, last_response.body
      end

      should "return a site map for any page id" do
        auth_get "/@spontaneous/map/#{@home.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.map(@home.id).to_json, last_response.body
      end

      should "return a site map for any url" do
        page = @project1
        auth_get "/@spontaneous/location#{@project1.path}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.map(@project1.id).to_json, last_response.body
      end

      should "return 404 when asked for map of non-existant page" do
        id = '9999'
        S::Content.stubs(:[]).with(id).returns(nil)
        auth_get "/@spontaneous/map/#{id}"
        assert last_response.status == 404
      end

      should "return the correct Last-Modified header for the site map" do
        now = Time.at(Time.now.to_i + 10000)
        S::Site.stubs(:modified_at).returns(now)
        auth_get '/@spontaneous/map'
        Time.httpdate(last_response.headers["Last-Modified"]).should == now
        auth_get "/@spontaneous/location#{@project1.path}"
        Time.httpdate(last_response.headers["Last-Modified"]).should == now
      end

      should "reply with a 304 Not Modified if the site hasn't been updated since last request" do
        datestring = "Sat, 03 Mar 2012 00:49:44 GMT"
        now = Time.httpdate(datestring)
        S::Site.stubs(:modified_at).returns(now)
        auth_get "/@spontaneous/map/#{@home.id}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring}
        last_response.status.should == 304
        auth_get "/@spontaneous/map", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring}
        last_response.status.should == 304
        auth_get "/@spontaneous/location#{@project1.path}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring}
        last_response.status.should == 304
      end

      should "return the map data if the site has been updated since last request" do
        datestring1 = "Sat, 03 Mar 2012 00:49:44 GMT"
        datestring2 = "Sat, 03 Mar 2012 01:49:44 GMT"
        now = Time.httpdate(datestring2)
        S::Site.stubs(:modified_at).returns(now)
        auth_get "/@spontaneous/map/#{@home.id}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring1}
        last_response.status.should == 200
        auth_get "/@spontaneous/location#{@project1.path}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring1}
        last_response.status.should == 200
      end

      should "reorder pieces" do
        auth_post "/@spontaneous/content/#{@job2.id}/position/0"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.in_progress.contents.first.id.should == @job2.id

        page = Content[@home.id]
        page.in_progress.contents.first.id.should == @job2.id
      end

      # should "reorder pages" do
      #   post "/@spontaneous/page/#{@about.id}/position/0"
      #   assert last_response.ok?
      #   last_response.content_type.should == "application/json;charset=utf-8"
      #   # can't actually be bothered to set this test up
      #   # @piece2_2.reload.pieces.first.target.id.should == @piece2_5.id
      # end

      context "saving" do
        setup do
          # @home = HomePage.new
          # @piece = Text.new
          # @home.in_progress << @piece
          # @home.save
          # @piece.save
        end

        should "update content field values" do
          params = {
            "field[#{@job1.fields.title.schema_id.to_s}][value]" => "Updated field_name_1"
          }
          auth_post "/@spontaneous/save/#{@job1.id}", params
          assert last_response.ok?
          last_response.content_type.should == "application/json;charset=utf-8"
          @job1 = Content[@job1.id]
          last_response.body.should == @job1.serialise_http(@user)
          @job1.fields.title.value.should ==  "Updated field_name_1"
        end

        should "update page field values" do
          params = {
            "field[#{@home.fields.title.schema_id.to_s}][value]" => "Updated title",
            "field[#{@home.fields.introduction.schema_id.to_s}][value]" => "Updated intro"
          }
          auth_post "/@spontaneous/save/#{@home.id}", params
          assert last_response.ok?
          last_response.content_type.should == "application/json;charset=utf-8"
          @home = Content[@home.id]
          last_response.body.should == @home.serialise_http(@user)
          @home.fields.title.value.should ==  "Updated title"
          @home.fields.introduction.value.should ==  "<p>Updated intro</p>\n"
        end

        should "update box field values" do
          box = @job1.images
          box.fields.title.to_s.should_not == "Updated title"
          params = {
            "field[#{box.fields.title.schema_id.to_s}][value]" => "Updated title"
          }
          auth_post "/@spontaneous/savebox/#{@job1.id}/#{box.schema_id.to_s}", params
          assert last_response.ok?
          last_response.content_type.should == "application/json;charset=utf-8"
          @job1 = Content[@job1.id]
          @job1.images.title.value.should == "Updated title"
        end

        should "generate an error if there is a field version conflict" do
          field = @job1.fields.title
          field.version = 3
          @job1.save.reload
          field = @job1.fields.title
          sid = field.schema_id.to_s
          params = { "fields" => {sid => "2"} }

          auth_post "/@spontaneous/version/#{@job1.id}", params
          assert last_response.status == 409, "Should have recieved a 409 conflict but instead received a #{last_response.status}"
          last_response.content_type.should == "application/json;charset=utf-8"
          result = Spontaneous.deserialise_http(last_response.body)
          result.should == {
            sid.to_sym => [ field.version, field.value ]
          }
        end

        should "generate an error if there is a field version conflict for boxes" do
          box = @job1.images
          field = box.fields.title
          field.version = 3
          @job1.save.reload
          box = @job1.images
          field = box.fields.title
          sid = field.schema_id.to_s
          params = { "fields" => {sid => "2"} }

          auth_post "/@spontaneous/version/#{@job1.id}/#{box.schema_id.to_s}", params
          assert last_response.status == 409, "Should have recieved a 409 conflict but instead received a #{last_response.status}"
          last_response.content_type.should == "application/json;charset=utf-8"
          result = Spontaneous.deserialise_http(last_response.body)
          result.should == {
            sid.to_sym => [ field.version, field.value ]
          }
        end

      end
    end # context @spontaneous

    context "Visibility" do
      setup do
        Spontaneous.stubs(:reload!)
        # @home = HomePage.new
        # @piece = Text.new
        # @home.in_progress << @piece
        # @home.save
        # @piece.save
      end
      should "be toggled" do
        @job1.reload.visible?.should == true
        auth_post "/@spontaneous/toggle/#{@job1.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        Spot::JSON.parse(last_response.body).should == {:id => @job1.id, :hidden => true}
        @job1.reload.visible?.should == false
        auth_post "/@spontaneous/toggle/#{@job1.id}"
        assert last_response.ok?, "Expected status 200 but recieved #{last_response.status}"
        @job1.reload.visible?.should == true
        Spot::JSON.parse(last_response.body).should == {:id => @job1.id, :hidden => false}
      end
    end

    context "preview" do
      setup do
        Spontaneous.stubs(:reload!)
        @now = Time.now
        Time.stubs(:now).returns(@now)
      end
      should "return rendered root page" do
        get "/"
        assert last_response.ok?
        last_response.content_type.should == "text/html;charset=utf-8"
        assert_equal S::Render.with_preview_renderer { @home.render }, last_response.body
      end

      should "return rendered child-page" do
        get "/project1"
        assert last_response.ok?
        last_response.content_type.should == "text/html;charset=utf-8"
        assert_equal S::Render.with_preview_renderer { @project1.render }, last_response.body
      end

      should "return alternate formats" do
        Project.add_output :js
        get "/project1.js"
        assert last_response.ok?
        last_response.content_type.should == "application/javascript;charset=utf-8"
        assert_equal S::Render.with_preview_renderer { @project1.render(:js) }, last_response.body
      end

      should "allow pages to have css formats" do
        Project.add_output :css
        get "/project1.css"
        assert last_response.ok?
        last_response.content_type.should == "text/css;charset=utf-8"
        assert_equal S::Render.with_preview_renderer { @project1.render(:css) }, last_response.body
      end

      should "return cache-busting headers" do
        ["/project1", "/"].each do |path|
          get path
          assert last_response.ok?
          last_response.headers['Expires'].should == @now.to_formatted_s(:rfc822)
          last_response.headers['Last-Modified'].should == @now.to_formatted_s(:rfc822)
        end
      end

      should "return cache-control headers" do
        ["/project1", "/"].each do |path|
          get path
          assert last_response.ok?
          ["no-store", 'no-cache', 'must-revalidate', 'max-age=0'].each do |p|
            last_response.headers['Cache-Control'].should =~ %r(#{p})
          end
        end
      end

      should "render SASS templates" do
        get "/css/sass_template.css"
        assert last_response.ok?, "Should return 200 but got #{last_response.status}"
        last_response.body.should =~ /color: #ffeeff/
      end

      should "compile CoffeeScript" do
        get "/js/coffeescript.js"
        assert last_response.ok?, "Should return 200 but got #{last_response.status}"
        last_response.body.should =~ /square = function/
        last_response.content_type.should == "application/javascript;charset=utf-8"
      end

      should "accept POST requests" do
        Project.expects(:posted!).with(@project1)
        Project.request :post do
          Project.posted!(page)
        end
        post "/project1"
      end
    end

    context "static files" do
      setup do
        Spontaneous.stubs(:reload!)
      end
      should "work for site" do
        get "/test.html"
        assert last_response.ok?
        assert_equal <<-HTML, last_response.body
<html><head><title>Test</title></head></html>
        HTML
      end
      should "work for @spontaneous files" do
        get "/@spontaneous/static/test.html"
        assert last_response.ok?
        assert_equal <<-HTML, last_response.body
<html><head><title>@spontaneous Test</title></head></html>
        HTML
      end
      # should "return a custom favicon" do
      #   get "/favicon.ico"
      #   assert last_response.ok?
      #   p @app_dir
      #   assert_equal File.read(@app_dir / 'static/favicon.ico'), last_response.body
      # end
    end

    context "media files" do
      setup do
        Spontaneous.stubs(:reload!)
        # Spontaneous.media_dir = File.join(File.dirname(__FILE__), "../fixtures/media")
      end
      teardown do
      end
      should "be available under /media" do
        get "/media/101/003/rose.jpg"
        assert last_response.ok?
        last_response.content_type.should == "image/jpeg"
      end
    end

    context "file uploads" do
      setup do
        Spontaneous.stubs(:reload!)
        @src_file = Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/images/rose.jpg")).realpath.to_s
        @upload_id = 9723
        Time.stubs(:now).returns(Time.at(1288882153))
        Spontaneous::Media.stubs(:upload_index).returns(23)
      end

      should "replace values of fields immediately when required" do
        @image1.image.processed_value.should == ""
        auth_post "@spontaneous/file/replace/#{@image1.id}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg"), "field" => @image1.image.schema_id.to_s
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @image1 = Content[@image1.id]
        src = @image1.image.src
        src.should =~ /^\/media(.+)\/rose\.jpg$/
        Spot::JSON.parse(last_response.body).should == @image1.image.export
        #   :id => @image1.id,
        #   :src => src,
        #   :version => 1
        # }.to_json
        File.exist?(Media.to_filepath(src)).should be_true
        get src
        assert last_response.ok?
      end

      should "replace values of box file fields" do
        @job1.images.image.processed_value.should == ""
        auth_post "@spontaneous/file/replace/#{@job1.id}/#{@job1.images.schema_id}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg"), "field" => @job1.images.image.schema_id.to_s
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @job1 = Content[@job1.id]
        src = @job1.images.image.src
        src.should =~ /^\/media(.+)\/rose\.jpg$/
        Spot::JSON.parse(last_response.body).should == @job1.images.image.export
        #   :id => @job1.id,
        #   :src => src,
        #   :version => 1
        # }.to_json
        File.exist?(Media.to_filepath(src)).should be_true
        get src
        assert last_response.ok?
      end

      should "be able to wrap pieces around files using default addable class" do
        box = @job1.images
        current_count = box.contents.length
        first_id = box.contents.first.id.to_s

        auth_post "/@spontaneous/file/wrap/#{@job1.id}/#{box.schema_id.to_s}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg")
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        box = @job1.reload.images
        first = box.contents.first
        box.contents.length.should == current_count+1
        first.image.src.should =~ /^\/media(.+)\/#{File.basename(@src_file)}$/
          required_response = {
          :position => 0,
          :entry => first.export
        }
        Spot::JSON.parse(last_response.body).should == required_response
      end
    end
    context "Box contents" do
      setup do
        Spontaneous.stubs(:reload!)
      end

      should "allow addition of pages" do
        current_count = @home.projects.length
        auth_post "/@spontaneous/add/#{@home.id}/#{@home.projects.schema_id.to_s}/#{Project.schema_id.to_s}"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        @home.reload
        @home.projects.length.should == current_count+1
        @home.projects.first.must_be_instance_of(Project)
      end

      should "default to adding entries at the top" do
        current_count = @home.in_progress.contents.length
        first_id = @home.in_progress.contents.first.id
        @home.in_progress.contents.first.class.name.should_not == "BackTest::Image"
        auth_post "/@spontaneous/add/#{@home.id}/#{@home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.in_progress.contents.length.should == current_count+1
        @home.in_progress.contents.first.id.should_not == first_id
        @home.in_progress.contents.first.class.name.should == "BackTest::Image"
        required_response = {
          :position => 0,
          :entry => @home.in_progress.contents.first.export
        }
        Spot::JSON.parse(last_response.body).should == required_response
      end

      should "be removable" do
        target = @home.in_progress.first
        auth_post "/@spontaneous/destroy/#{target.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        Content[target.id].should be_nil
      end

      should "be addable at the bottom" do
        current_count = @home.in_progress.contents.length
        last_id = @home.in_progress.contents.last.id
        @home.in_progress.contents.last.class.name.should_not == "BackTest::Image"
        auth_post "/@spontaneous/add/#{@home.id}/#{@home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}", :position => -1
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.in_progress.contents.length.should == current_count+1
        @home.in_progress.contents.last.id.should_not == last_id
        @home.in_progress.contents.last.class.name.should == "BackTest::Image"
        required_response = {
          :position => -1,
          :entry => @home.in_progress.contents.last.export
        }
        Spot::JSON.parse(last_response.body).should == required_response
      end

      should "create pieces with the piece owner set to the logged in user" do
        auth_post "/@spontaneous/add/#{@home.id}/#{@home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}", :position => 0
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        @home.reload
        @home.in_progress.first.created_by_id.should == @user.id
        @home.in_progress.first.created_by.should == @user
      end
    end

    context "Page paths" do
      setup do
        Spontaneous.stubs(:reload!)
      end
      should "be editable" do
        @project1.path.should == '/project1'
        auth_post "/@spontaneous/slug/#{@project1.id}", 'slug' => 'howabout'
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @project1.reload
        @project1.path.should == "/howabout"
        Spot::JSON.parse(last_response.body).should == {:path => '/howabout', :slug => 'howabout' }
      end
      should "raise error when trying to save duplicate path" do
        auth_post "/@spontaneous/slug/#{@project1.id}", 'slug' => 'project2'
        last_response.status.should == 409
        @project1.reload.path.should == '/project1'
      end
      should "raise error when trying to save empty slug" do
        auth_post "/@spontaneous/slug/#{@project1.id}", 'slug' => ''
        last_response.status.should == 406
        @project1.reload.path.should == '/project1'
        auth_post "/@spontaneous/slug/#{@project1.id}"
        last_response.status.should == 406
        @project1.reload.path.should == '/project1'
      end
      should "provide a list of unavailable slugs for a page" do
        auth_get "/@spontaneous/slug/#{@project1.id}/unavailable"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        Spot::JSON.parse(last_response.body).should == %w(project2 project3)
      end
      should "be syncable with the page title" do
        @project1.title = "This is Project"
        @project1.save
        auth_post "/@spontaneous/slug/#{@project1.id}/titlesync"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @project1.reload
        @project1.path.should == "/this-is-project"
        Spot::JSON.parse(last_response.body).should == {:path => '/this-is-project', :slug => 'this-is-project' }
      end
    end
    context "UIDs" do
      setup do
        # editing UIDs is a developer only activity
        @user.update(:level => Spontaneous::Permissions[:root])
        @user.save
      end

      should "be editable" do
        uid = "fishy"
        @project1.uid.should_not == uid
        auth_post "/@spontaneous/uid/#{@project1.id}", 'uid' => uid
        assert last_response.ok?
        Spot::JSON.parse(last_response.body).should == {:uid => uid}
        @project1.reload.uid.should == uid
      end

      should "not be editable by non-developer users" do
        @user.stubs(:developer?).returns(false)
        uid = "boom"
        orig = @project1.uid
        @project1.uid.should_not == uid
        auth_post "/@spontaneous/uid/#{@project1.id}", 'uid' => uid
        assert last_response.status == 401
        @project1.reload.uid.should == orig
      end
    end
    context "Request cache" do
      setup do
        Spontaneous.stubs(:reload!)
      end

    end

    context "Publishing" do
      setup do
        Spontaneous.stubs(:reload!)
        S::Permissions::UserLevel[:editor].stubs(:can_publish?).returns(true)
        @now = Time.now
        Time.stubs(:now).returns(@now)
      end

      teardown do
      end

      should "be able to retrieve a serialised list of all unpublished changes" do
        auth_get "/@spontaneous/publish/changes"
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
        last_response.content_type.should == "application/json;charset=utf-8"
        last_response.body.should == Change.serialise_http
      end

      should "be able to start a publish with a set of change sets" do
        Site.expects(:publish_pages).with([@project1.id])
        auth_post "/@spontaneous/publish/publish", :page_ids => [@project1.id]
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
      end

      should "not launch publish if list of changes is empty" do
        Site.expects(:publish_pages).with().never
        auth_post "/@spontaneous/publish/publish", :change_set_ids => ""
        assert last_response.status == 400, "Expected 400, recieved #{last_response.status}"

        auth_post "/@spontaneous/publish/publish", :change_set_ids => nil
        assert last_response.status == 400
      end
      should "recognise when the list of changes is complete" do
        Site.expects(:publish_pages).with([@home.id, @project1.id])
        auth_post "/@spontaneous/publish/publish", :page_ids => [@home.id, @project1.id]
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
      end
    end

    context "New sites" do
      setup do
        Spontaneous.stubs(:reload!)
        @root_class = Site.root.class
        Content.delete
      end
      should "raise a 406 Not Acceptable error when downloading page details" do
        auth_get "/@spontaneous/location/"
        last_response.status.should == 406
      end
      should "create a homepage of the specified type" do
        auth_post "/@spontaneous/root", 'type' => @root_class.schema_id
        assert last_response.ok?
        Site.root.must_be_instance_of(@root_class)
        Site.root.title.value.should =~ /Home/
      end
      should "only create one root" do
        auth_post "/@spontaneous/root", 'type' => @root_class.schema_id
        assert last_response.ok?
        Content.count.should == 1
        auth_post "/@spontaneous/root", 'type' => @root_class.schema_id
        assert last_response.status == 403
        Content.count.should == 1
      end
    end

    context "when working with aliases" do
      setup do
        Spontaneous.stubs(:reload!)
      end

      teardown do
      end

      should "be able to retrieve a list of potential targets" do
        auth_get "/@spontaneous/targets/#{LinkedJob.schema_id}/#{@home.id}/#{@home.in_progress.schema_id}"
        assert last_response.ok?
        expected = LinkedJob.targets(@home, @home.in_progress)
        response = Spot::JSON.parse(last_response.body)
        response[:pages].should == 1
        response[:page].should == 1
        response[:total].should == expected.length

        response[:targets].should == expected.map { |job|
          { :id => job.id,
            :title => job.title.to_s,
            :icon => job.image.export }
        }
      end

      should "be able to filter targets using a search string" do
        auth_get "/@spontaneous/targets/#{LinkedJob.schema_id}/#{@home.id}/#{@home.in_progress.schema_id}", {"query" => "job 3"}
        assert last_response.ok?
        expected = [@job3]
        response = Spot::JSON.parse(last_response.body)
        response[:pages].should == 1
        response[:page].should == 1
        response[:total].should == expected.length
        response[:targets].should == expected.map { |job|
          { :id => job.id,
            :title => job.title.to_s,
            :icon => job.image.export }
        }
      end

      should "be able to add an alias to a box" do
        @home.featured_jobs.contents.length.should == 0
        auth_post "/@spontaneous/alias/#{@home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_id' => Job.first.id, "position" => 0
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.featured_jobs.contents.length.should == 1
        a = @home.featured_jobs.first
        a.alias?.should be_true
        a.target.should == Job.first
        required_response = {
          :position => 0,
          :entry => @home.featured_jobs.contents.first.export(@user)
        }
        Spot::JSON.parse(last_response.body).should == required_response
      end

      should "be able to add an alias to a box at any position" do
        @home.featured_jobs << Job.new
        @home.featured_jobs << Job.new
        @home.featured_jobs << Job.new
        @home.save.reload
        @home.featured_jobs.contents.length.should == 3
        auth_post "/@spontaneous/alias/#{@home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_id' => Job.first.id, "position" => 2
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.featured_jobs.contents.length.should == 4
        a = @home.featured_jobs[2]
        a.alias?.should be_true
        a.target.should == Job.first
        required_response = {
          :position => 2,
          :entry => @home.featured_jobs[2].export(@user)
        }
        Spot::JSON.parse(last_response.body).should == required_response
      end

      context "of non-content targets" do
        setup do
          @target_id = target_id = 9999
          @target = target = mock()
          @target.stubs(:id).returns(@target_id)
          @target.stubs(:title).returns("custom object")
          @target.stubs(:to_json).returns({:title => "custom object", :id => @target_id}.to_json)
          @target.stubs(:alias_title).returns("custom object")
          @target.stubs(:exported_alias_icon).returns(nil)

          LinkedSomething = Class.new(Piece) do
            alias_of proc { [target] }, :lookup => lambda { |id|
            return target if id == target_id
            nil
          }
          end
        end

        teardown do
          BackTest.send(:remove_const, LinkedSomething) rescue nil
        end

        should "interface with lists of non-content targets" do
          box = @home.boxes[:featured_jobs]
          box._prototype.allow LinkedSomething
          auth_post "/@spontaneous/alias/#{@home.id}/#{box.schema_id.to_s}", 'alias_id' => LinkedSomething.schema_id.to_s, 'target_id' => @target_id, "position" => 0
          assert last_response.status == 200, "Expected a 200 but got #{last_response.status}"
          @home.reload
          a = @home.featured_jobs[0]
          a.alias?.should be_true
          a.target.should == @target
        end
      end
    end

    context "Schema conflicts" do
      setup do
        # enable schema validation errors by creating and using a permanent map file
        @schema_map = File.join(Dir.tmpdir, "schema.yml")
        FileUtils.rm(@schema_map) if File.exists?(@schema_map)
        S.schema.schema_map_file = @schema_map
        S.schema.validate!
        S.schema.write_schema
        S.schema.schema_loader_class = S::Schema::PersistentMap
        Job.field :replaced
        @df1 = Job.field_prototypes[:title]
        @af1 = Job.field_prototypes[:replaced]
        @f1  = Job.field_prototypes[:image]
        @uid = @df1.schema_id.to_s
        Job.stubs(:field_prototypes).returns({:replaced => @af1, :image => @f1})
        Job.stubs(:fields).returns([@af1, @f1])
        lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
        # hammer, meet nut
        S::Rack::Back::EditingInterface.use Spontaneous::Rack::Reloader
        S::Rack::Back::Preview.use Spontaneous::Rack::Reloader
        Spontaneous::Loader.stubs(:reload!)
      end

      teardown do
        S.schema.schema_loader_class = S::Schema::TransientMap
        FileUtils.rm(@schema_map) if File.exists?(@schema_map)
      end

      should "raise a 412 error" do
        get '/@spontaneous/'
        assert last_response.status == 412, "Schema validation errors should raise a 412 but instead recieved a #{last_response.status}"
      end

      should "present a dialogue page with possible solutions" do
        auth_get '/@spontaneous/'
        assert last_response.status == 412, "Schema validation errors should raise a 412 but instead recieved a #{last_response.status}"
        last_response.body.should =~ %r{<form action="/@spontaneous/schema/delete" method="post"}
        last_response.body.should =~ %r{<input type="hidden" name="uid" value="#{@df1.schema_id}"}

        last_response.body.should =~ %r{<form action="/@spontaneous/schema/rename" method="post"}
        last_response.body.should =~ %r{<input type="hidden" name="ref" value="#{@af1.schema_name}"}
      end

      should "present a dialogue page with possible solutions when in preview mode" do
        auth_get '/'
        assert last_response.status == 412, "Schema validation errors should raise a 412 but instead recieved a #{last_response.status}"
        last_response.body.should =~ %r{<form action="/@spontaneous/schema/delete" method="post"}
        last_response.body.should =~ %r{<input type="hidden" name="uid" value="#{@df1.schema_id}"}

        last_response.body.should =~ %r{<form action="/@spontaneous/schema/rename" method="post"}
        last_response.body.should =~ %r{<input type="hidden" name="ref" value="#{@af1.schema_name}"}
      end

      should "perform renames via a link" do
        action ="/@spontaneous/schema/rename"
        auth_post action, "uid" => @df1.schema_id, "ref" => @af1.schema_name, "origin" => "/@spontaneous"
        last_response.status.should == 302
        begin
          S.schema.validate!
        rescue Spontaneous::SchemaModificationError => e
          flunk("Schema modification link should have resolved schema errors")
        end
      end

      should "perform deletions via a link" do
        action ="/@spontaneous/schema/delete"
        auth_post action, "uid" => @df1.schema_id, "origin" => "/@spontaneous"
        last_response.status.should == 302
        begin
          S.schema.validate!
        rescue Spontaneous::SchemaModificationError => e
          flunk("Schema modification link should have resolved schema errors")
        end
      end

      should "redirect back to original page"
    end
    context "sharded uploading" do
      setup do
        Spontaneous.stubs(:reload!)
        @image = File.expand_path("../../fixtures/sharding/rose.jpg", __FILE__)
        # read the digest dynamically in case I change that image
        @image_digest = S::Media.digest(@image)
      end

      teardown do
      end

      should "have the right setting for shard_dir" do
        shard_path = File.join(@site.root / 'cache/tmp')
        Spontaneous.shard_path.should == shard_path
        Spontaneous.shard_path("abcdef0123").should == shard_path/ "ab/cd/abcdef0123"
      end

      should "know when it already has a shard" do
        hash = '4d68c8f13459c0edb40504de5003ec2a6b74e613'
        FileUtils.touch(Spontaneous.shard_path(hash))
        FileUtils.expects(:touch).with(Spontaneous.shard_path(hash))
        auth_get "/@spontaneous/shard/#{hash}"
        last_response.status.should == 200
      end

      should "know when it doesn't have a shard" do
        auth_get "/@spontaneous/shard/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        last_response.status.should == 404
      end

      should "receive a shard and put it in the right place" do
        auth_post "@spontaneous/shard/#{@image_digest}", "file" => ::Rack::Test::UploadedFile.new(@image, "image/jpeg")
        assert last_response.ok?
        auth_get "/@spontaneous/shard/#{@image_digest}"
        last_response.status.should == 200
      end

      should "return an error if the uploaded file has the wrong hash" do
        S::Media.expects(:digest).with(anything).returns("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
        auth_post "@spontaneous/shard/#{@image_digest}", "file" => ::Rack::Test::UploadedFile.new(@image, "image/jpeg")
        last_response.status.should == 409
      end

      should "reassemble multiple parts into a single file and attach it to a content item" do
        parts = %w(xaa xab xac xad xae xaf xag)
        paths = parts.map { |part| File.expand_path("../../fixtures/sharding/#{part}", __FILE__) }
        hashes = paths.map { |path| S::Media.digest(path) }
        paths.each_with_index do |part, n|
          auth_post "/@spontaneous/shard/#{hashes[n]}", "file" => ::Rack::Test::UploadedFile.new(part, "application/octet-stream")
        end
        hashes.each do |hash|
          auth_get "/@spontaneous/shard/#{hash}"
          last_response.status.should == 200
        end
        @image1.image.processed_value.should == ""
        dataset = mock()
        S::Content.stubs(:for_update).returns(dataset)
        dataset.stubs(:first).with(:id => @image1.id.to_s).returns(@image1)
        dataset.stubs(:first).with(:id => @image1.id).returns(@image1)
        # S::Content.stubs(:[]).with(@image1.id.to_s).returns(@image1)
        # S::Content.stubs(:[]).with(@image1.id).returns(@image1)
        auth_post "/@spontaneous/shard/replace/#{@image1.id}", "filename" => "rose.jpg",
          "shards" => hashes, "field" => @image1.image.schema_id.to_s
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @image1 = Content[@image1.id]
        src = @image1.image.src
        src.should =~ %r{^(.+)/rose\.jpg$}
        Spot::JSON.parse(last_response.body).should == @image1.image.export
        File.exist?(Media.to_filepath(src)).should be_true
        S::Media.digest(Media.to_filepath(src)).should == @image_digest
      end

      should "be able to wrap pieces around files using default addable class" do
        parts = %w(xaa xab xac xad xae xaf xag)
        paths = parts.map { |part| File.expand_path("../../fixtures/sharding/#{part}", __FILE__) }
        hashes = paths.map { |path| S::Media.digest(path) }
        paths.each_with_index do |part, n|
          auth_post "/@spontaneous/shard/#{hashes[n]}", "file" => ::Rack::Test::UploadedFile.new(part, "application/octet-stream")
        end
        hashes.each do |hash|
          auth_get "/@spontaneous/shard/#{hash}"
          last_response.status.should == 200
        end
        box = @job1.images
        current_count = box.contents.length
        first_id = box.contents.first.id.to_s

        auth_post "/@spontaneous/shard/wrap/#{@job1.id}/#{box.schema_id.to_s}", "filename" => "rose.jpg", "shards" => hashes, "mime_type" => "image/jpeg"
        assert last_response.ok?, "Should have got status 200 but got #{last_response.status}"
        last_response.content_type.should == "application/json;charset=utf-8"
        box = @job1.reload.images
        first = box.contents.first
        box.contents.length.should == current_count+1
        first.image.src.should =~ %r{^(.+)/rose\.jpg$}
        required_response = {
          :position => 0,
          :entry => first.export
        }
        Spot::JSON.parse(last_response.body).should == required_response
      end
    end


    context "making modifications" do
      setup do
        Spontaneous.stubs(:reload!)
      end
      should "record the currently logged in user" do
        page = @home.in_progress.last
        auth_post "/@spontaneous/toggle/#{page.id}"
        assert last_response.ok?, "Expected status 200 but received #{last_response.status}"
        page.reload
        page.pending_modifications(:visibility).first.user.should == @user
      end
    end

    context "date fields" do
      setup do
        Spontaneous.stubs(:reload!)
      end
      should "provide a format value" do
        field = Job.field :date, :date, :format => "%Y %d %a"
        auth_get "/@spontaneous/metadata"
        schema = Spot::JSON.parse(last_response.body)
        field = schema[:types][:"BackTest.Job"][:fields].detect { |f| f[:name] == "date" }
        field[:date_format].should ==  "%Y %d %a"
      end
    end

    context "select fields" do
      setup do
        Spontaneous.stubs(:reload!)
      end

      teardown do
      end

      should "be able to provide a static value list" do
        # static lists should be included in the field definitions
        field = Job.field :client, :select, :options => [["a", "Value A"], ["b", "Value B"]]
        auth_get "/@spontaneous/metadata"

        schema = Spot::JSON.parse(last_response.body)
        field = schema[:types][:"BackTest.Job"][:fields].detect { |f| f[:name] == "client" }
        field[:option_list].should == [["a", "Value A"], ["b", "Value B"]]
      end

      should "be able to provide a dynamic value list" do
        list = mock()
        options = [["a", "Value A"], ["b", "Value B"]]
        list.expects(:values).with(@job1).returns(options)
        field = Job.field :client, :select, :options => proc { |content| list.values(content) }
        auth_get "/@spontaneous/options/#{field.schema_id}/#{@job1.id}"
        assert last_response.ok?,  "Expected status 200 but received #{last_response.status}"
        result = Spot::JSON.parse(last_response.body)
        result.should == options
      end

      should "be able to provide a dynamic value list for a box field" do
        list = mock()
        options = [["a", "Value A"], ["b", "Value B"]]
        list.expects(:values).with(@job1.images).returns(options)
        field = Job.boxes.images.instance_class.field :client, :select, :options => proc { |box| list.values(box) }
        auth_get "/@spontaneous/options/#{field.schema_id}/#{@job1.id}/#{Job.boxes.images.schema_id}"
        assert last_response.ok?,  "Expected status 200 but received #{last_response.status}"
        result = Spot::JSON.parse(last_response.body)
        result.should == options
      end
    end
  end
end

