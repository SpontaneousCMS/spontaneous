# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# set :environment, :test


class AuthenticationTest < MiniTest::Spec
  include ::Rack::Test::Methods


  def create_user(name, level)
    user = Permissions::User.create({
      :name => "#{name.capitalize}",
      :email => "#{name}@example.org",
      :login => name,
      :password => "#{name}_password",
      :password_confirmation => "#{name}_password"
    })
    user.update(:level => level)
    user
  end

  @@version = 0

  def version
    @@version += 1
  end

  def app
    Spontaneous::Rack::Back.application
  end

  def root
    @root
  end

  def about
    @about
  end

  def root_user
    @root_user
  end

  def admin_user
    @admin_user
  end

  def editor_user
    @editor_user
  end

  def guest_user
    @guest_user
  end

  def disabled_user
    @disabled_user
  end

  def login_user(user, params={})
    post "/@spontaneous/login", {"user[login]" => user.login, "user[password]" => user.password}.merge(params)
    @user = user
  end

  def auth_post(path, params={})
    key = @user.access_keys.first
    post(path, params.merge("__key" => key.key_id))
  end

  def auth_get(path, params={})
    key = @user.access_keys.first
    get(path, params.merge("__key" => key.key_id))
  end

  def setup
    @site = setup_site

    @site.config.publishing_delay nil
    @site.config.site_domain "example.com"
    @site.config.site_id "example_com"

    # Site.database = DB
    @site.paths.add :templates, File.expand_path("../../fixtures/public/templates", __FILE__)
    # see http://benprew.posterous.com/testing-sessions-with-sinatra
    # app.send(:set, :sessions, false)
    S::Rack::Back::EditingInterface.set :sessions, false
    Spontaneous.stubs(:media_dir).returns(File.expand_path('../../fixtures/permissions/media', __FILE__))
  end

  def teardown
    teardown_site
  end
  def assert_login_page(path = nil, method = "GET")
    assert last_response.status == 401, "#{method} #{path} should have status 401 but has #{last_response.status}"
    last_response.body.should =~ %r{<form.+action="/@spontaneous/login"}
    last_response.body.should =~ %r{<form.+method="post"}
    last_response.body.should =~ %r{<input.+name="user\[login\]"}
    last_response.body.should =~ %r{<input.+name="user\[password\]"}
  end

  def post_paths
    %(/save/#{root.id} /savebox/#{root.id}/#{root.boxes[:editor_level].schema_id} /content/#{root.id}/position/0 /file/upload/#{root.id} /file/replace/#{root.id} /file/wrap/#{root.id}/#{root.boxes[:pages].schema_id} /add/#{root.id}/#{root.boxes[:pages].schema_id}/#{SitePage.schema_id} /destroy/#{root.id} /slug/#{root.id} /slug/#{root.id}/unavailable /toggle/#{root.id} /schema/delete /schema/rename)
  end

  def get_paths
    %(/root /page/#{root.id} /metadata /map /map/#{root.id} /location/about)
  end

  context "Authentication:" do
    setup do
      # Spontaneous::Schema.reset!

      class C < Spontaneous::Piece
        field :photo, :image, :write_level => :root
      end
      class D < Spontaneous::Piece; end

      class SitePage < Spontaneous::Page
        # page_style :default
        field :editor_level, :user_level => :editor
          field :admin_level, :user_level => :admin
        field :root_level, :user_level => :root
        field :mixed_level, :read_level => :editor, :write_level => :root
        field :default_level

        box :pages

        box :editor_level, :user_level => :editor do
          field :editor_level, :user_level => :editor
            field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'AuthenticationTest::D', :user_level => :editor
            allow :'AuthenticationTest::C', :user_level => :root
        end

        box :admin_level, :user_level => :admin do
          field :editor_level, :user_level => :editor
            field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'AuthenticationTest::C', :user_level => :admin
          allow :'AuthenticationTest::D', :user_level => :root
        end

        box :root_level, :user_level => :root do
          field :editor_level, :user_level => :editor
            field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'AuthenticationTest::C', :user_level => :root
        end

        box :mixed_level, :read_level => :editor, :write_level => :root do
          field :editor_level, :user_level => :editor
            field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'AuthenticationTest::C', :user_level => :editor
        end

        box :default_level do
          field :editor_level, :user_level => :editor
            field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'AuthenticationTest::C'
        end
      end
      Content.delete
      Permissions::User.delete
      Permissions::AccessKey.delete
      Spontaneous.environment = :test
      Permissions::UserLevel.stubs(:level_file).returns(File.expand_path('../../fixtures/permissions', __FILE__) / 'config/user_levels.yml')

      @root = SitePage.create
      @root.save

      @about = SitePage.create(:uid => 'about', :slug => "about")
      @root.pages << @about
      piece = C.new
      @root.boxes[:root_level] << piece
      piece = C.new
      @root.boxes[:root_level] << piece
      @root.save

      @root_user = create_user('root', Permissions::UserLevel.root)
      @admin_user = create_user('admin', Permissions::UserLevel.admin)
      @editor_user = create_user('editor', Permissions::UserLevel.editor)
      @guest_user = create_user('guest', Permissions::UserLevel.none)
      @disabled_user = create_user('disabled', Permissions::UserLevel.admin)
      @disabled_user.update(:disabled => true)
    end

    teardown do
      [:C, :D, :SitePage].each { |k| AuthenticationTest.send(:remove_const, k) rescue nil }
      Content.delete
      Permissions::User.delete
      Permissions::AccessKey.delete
    end

    context "Unauthorised sessions" do
      should "redirect / to /@spontaneous" do
        get "/"
        assert last_response.status == 302
        last_response.headers["Location"].should =~ %r{/@spontaneous$}
      end

      should "redirect /* to /@spontaneous" do
        get "/about"
        assert last_response.status == 302
        last_response.headers["Location"].should =~ %r{/@spontaneous$}
      end

      should "see a login page at /@spontaneous" do
        get "/@spontaneous"
        assert_login_page
      end

      should "see a login page for all GETs" do
        get_paths.split.each do |path|
          get "/@spontaneous#{path}"
          assert_login_page path
        end
      end

      should "see a login page for all POSTs" do
        post_paths.split.each do |path|
          post "/@spontaneous#{path}"
          assert_login_page(path, "POST")
        end
      end

      should "get access to static files" do
        get "/@spontaneous/static/favicon.ico"
        assert last_response.status == 200
      end

      should "get access to Javascript files" do
        get "/@spontaneous/js/init.js"
        assert last_response.status == 200
      end

      should "get access to CSS files" do
        get "/@spontaneous/css/v2.css"
        assert last_response.status == 200
      end

      should "get access to media files" do
        get '/media/image.jpg'
        assert last_response.status == 200
      end

      context "Logging in" do
        should "fail unless provided with a login & password" do
          post "/@spontaneous/login", "user[login]" => "", "user[password]" => ""
          assert_login_page("/@spontaneous/login", "POST")
        end

        should "fail for invalid login names" do
          post "/@spontaneous/login", "user[login]" => "noone", "user[password]" => "wrong"
          assert_login_page("/@spontaneous/login", "POST")
        end

        should "fail for invalid passwords" do
          post "/@spontaneous/login", "user[login]" => "editor", "user[password]" => "wrong"
          assert_login_page("/@spontaneous/login", "POST")
        end

        should "fail for disabled users" do
          post "/@spontaneous/login", "user[login]" => "disabled", "user[password]" => "disabled_password"
          assert_login_page("/@spontaneous/login", "POST")
        end

        should "succeed and redirect to /@spontaneous for correct login & password" do
          # post "/@spontaneous/login", "user[login]" => "admin", "user[password]" => "admin_password"
          login_user(@admin_user, "origin" => "/103/preview")
          assert last_response.status == 302, "Status was #{last_response.status} not 302"
          last_response.headers["Location"].should =~ %r{/@spontaneous/103/preview$}
        end

        should "set the secure flag for cookies delivered behind https" do
          clear_cookies
          rack_mock_session.cookie_jar[S::Rack::AUTH_COOKIE].should be_nil
          user = @admin_user
          post "https://example.org/@spontaneous/login", {"user[login]" => user.login, "user[password]" => user.password}
          cookies = rack_mock_session.cookie_jar.instance_variable_get("@cookies")
          cookie = cookies.detect { |c| c.name == S::Rack::AUTH_COOKIE }
          cookie.secure?.should be_true
        end

        should "set the secure flag for cookies delivered behind https when reauthenticating" do
          clear_cookies
          key = @admin_user.logged_in!
          post "https://example.org/@spontaneous/reauthenticate", "api_key" => key.key_id, "origin" => "/99/edit"
          cookies = rack_mock_session.cookie_jar.instance_variable_get("@cookies")
          cookie = cookies.detect { |c| c.name == S::Rack::AUTH_COOKIE }
          cookie.secure?.should be_true
          cookie_options = cookie.instance_variable_get("@options")
          cookie_options.key?("HttpOnly").should be_true
        end

        should "succeed and return an api key value for correct login over XHR" do
          key = Spontaneous::Permissions::AccessKey.new
          Spontaneous::Permissions::AccessKey.expects(:new).returns(key)
          post "/@spontaneous/login", { "user[login]" => "admin", "user[password]" => "admin_password" }, {"HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
          assert last_response.status == 200, "Status was #{last_response.status} not 200"
          result = Spot::JSON.parse(last_response.body)
          result[:key].should == key.key_id
          result[:redirect].should == "/@spontaneous"
        end

        should "accept a valid API key for re-authentication" do
          key = @admin_user.logged_in!
          post "/@spontaneous/reauthenticate", "api_key" => key.key_id, "origin" => "/99/edit"
          assert last_response.status == 302, "Status was #{last_response.status} not 302"
          last_response.headers["Location"].should =~ %r{/@spontaneous/99/edit$}
        end

        should "reject invalid API key" do
          post "/@spontaneous/reauthenticate", "key" => "invalid"
          assert_login_page("/@spontaneous/reauthenticate", "POST")
        end
      end

      context "Logged in users" do
        setup do
          login_user(@editor_user)
        end

        teardown do
          clear_cookies
        end

        should "need to supply API key in params for all POSTs" do
          post_paths.split.each do |path|
            post "/@spontaneous#{path}"
            assert_login_page(path, "POST")
          end
        end

        should "need to supply API key in params for all GETs" do
          get_paths.split.each do |path|
            get "/@spontaneous#{path}"
            assert_login_page path
          end
        end

        should "be able to view the preview" do
          get "/"
          assert last_response.ok?
        end

        should "be able to view the editing interface" do
          get "/@spontaneous"
          assert last_response.ok?, "Expected 200 but got #{last_response.status}"
        end

        should "be able to logout" do
          auth_post "/@spontaneous/logout"
          assert last_response.status == 401
          rack_mock_session.cookie_jar.merge(last_response.headers["set-cookie"])
          rack_mock_session.cookie_jar[Spontaneous::Rack::AUTH_COOKIE].value.should == ""
        end

        # context "providing an API key in the request" do
        #   should "be able to see previously forbidden fruit" do
        #     get "/@spontaneous/root"
        #     assert last_response.ok?
        #   end
      end

    end

    context "User levels" do
      context "Root access" do
        setup do
          login_user(@root_user)
        end

        teardown do
          clear_cookies
        end

        should "be able to update root level fields" do
          field = root.fields.root_level
          auth_post "/@spontaneous/save/#{root.id}", "field[#{field.schema_id}][unprocessed_value]" => "Updated"
          assert last_response.ok?
          root.reload.fields[:root_level].value.should == "Updated"
        end

        should "be able to add to root level box" do
          klass = AuthenticationTest::C
          auth_post "/@spontaneous/add/#{root.id}/#{root.boxes[:root_level].schema_id}/#{klass.schema_id}"
          assert last_response.ok?
        end
      end
      context "Admin access" do
        setup do
          @root_copy = root
          login_user(@admin_user)
        end

        teardown do
          clear_cookies
        end

        should "not be able to update root level fields" do
          value = "Updated #{version}"
          field = root.fields[:root_level]
          auth_post "/@spontaneous/save/#{root.id}", "field[#{field.schema_id}][unprocessed_value]" => value
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
          root.reload.fields[:root_level].value.should == @root_copy.root_level.value
        end

        should "be able to update admin level fields" do
          value = "Updated #{version}"
          field = root.fields[:admin_level]
          auth_post "/@spontaneous/save/#{root.id}", "field[#{field.schema_id}][unprocessed_value]" => value
          assert last_response.ok?
          root.reload.fields[:admin_level].value.should == value
        end

        should "not be able to add to root level box" do
          auth_post "/@spontaneous/add/#{root.id}/#{root.boxes[:root_level].schema_id}/#{AuthenticationTest::C.schema_id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        should "not be able to add root level types to admin level box" do
          auth_post "/@spontaneous/add/#{root.id}/#{root.boxes[:admin_level].schema_id}/#{AuthenticationTest::D.schema_id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        should "be able to add to admin level box" do
          auth_post "/@spontaneous/add/#{root.id}/#{root.boxes[:admin_level].schema_id}/#{AuthenticationTest::C.schema_id}"
          # post "/@spontaneous/add/#{root.id}/admin_level/AuthenticationTest::C"
          assert last_response.ok?
        end

        should "not be able to update fields from root level box" do
          value = "Updated #{version}"
          field = root.fields[:editor_level]
          auth_post "/@spontaneous/savebox/#{root.id}/#{root.boxes[:root_level].schema_id}", "field[#{field.schema_id}][unprocessed_value]" => value
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        should "not be able to update root level fields from admin level box" do
          value = "Updated #{version}"
          field = root.boxes[:admin_level].fields[:root_level]
          auth_post "/@spontaneous/savebox/#{root.id}/#{root.boxes[:admin_level].schema_id}", "field[#{field.schema_id}][unprocessed_value]" => value
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        should "not be able to delete from root level box" do
          piece = root.boxes[:root_level].contents.first
          pieces = root.reload.boxes[:root_level].contents.length
          auth_post "/@spontaneous/destroy/#{piece.id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
          root.reload.boxes[:root_level].contents.length.should == pieces
        end
        should "not be able to wrap files in root level box" do
          src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
          auth_post "/@spontaneous/file/wrap/#{root.id}/#{root.boxes[:root_level].schema_id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg")
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end
        should "not be able to wrap files in box if allow permissions don't permit it" do
          src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
          # only type with an image field is C
          # editor_level box allows addition of type C but only by root
          # so the following should throw a perms error:
          auth_post "/@spontaneous/file/wrap/#{root.id}/#{root.boxes[:editor_level].schema_id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg")
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end
        should "not be able to re-order pieces in root level box" do
          piece = root.boxes[:root_level].contents.last
          auth_post "/@spontaneous/content/#{piece.id}/position/0"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
          root.reload.boxes[:root_level].contents.last.id.should == piece.id
        end

        should "not be able to replace root level fields" do
          piece = root.boxes[:root_level].contents.first
          src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
          field = piece.fields[:photo]
          auth_post "/@spontaneous/file/replace/#{piece.id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg"), "field" => field.schema_id
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        should "not be able to hide entries in root-level boxes" do
          piece = root.boxes[:root_level].contents.first
          auth_post "/@spontaneous/toggle/#{piece.id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        should "not be allowed to update path of pages without permission"
      end
      context "Editor access" do
        setup do
          @root_copy = root
          login_user(@editor_user)
        end

        teardown do
          clear_cookies
        end

        should "not be able to retrieve the list of changes" do
          auth_get "/@spontaneous/publish/changes"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end
      end
    end

  end
end

