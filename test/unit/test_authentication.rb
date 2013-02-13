# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# set :environment, :test


describe "Authentication" do
  include RackTestMethods

  Permissions = Spontaneous::Permissions

  def create_user(name, level)
    user = Permissions::User.create({
      :name => "#{name.capitalize}",
      :email => "#{name}@example.org",
      :login => name,
      :password => "#{name}_password"
    })
    user.update(:level => level)
    user
  end

  def version
    @version = (@version || 0) + 1
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

  # Used by the various auth_* methods
  def api_key
    @user.access_keys.first
  end

  before do
    @site = setup_site

    @site.config.publishing_delay nil
    @site.config.site_domain "example.com"
    @site.config.site_id "example_com"

    # Site.database = DB
    @site.paths.add :templates, File.expand_path("../../fixtures/public/templates", __FILE__)
    # see http://benprew.posterous.com/testing-sessions-with-sinatra
    # app.send(:set, :sessions, false)
    # S::Rack::Back::EditingInterface.set :sessions, false
    Spontaneous.stubs(:media_dir).returns(File.expand_path('../../fixtures/permissions/media', __FILE__))
  end

  after do
    teardown_site
  end

  # These paths don't have to be accurate because we only ever test for failure
  def post_paths
    %(/site/home
      /content/999/BOXID/TYPENAME
      /file/999/BOXID
      /shard/0000000000000000000000000000000000000000
      /schema/delete
    )
  end

  def get_paths
    %(/events
      /users
      /site
      /map
      /field/conflicts/999
      /page/999
      /alias/SCHEMAID/999/BOXID
      /changes
      /shard/0000000000000000000000000000000000000000
    )
  end

  describe "Authentication:" do
    before do
      # Spontaneous::Schema.reset!

      class ::C < Piece
        field :photo, :image, :write_level => :root
      end
      class ::D < Piece; end

      class ::SitePage < Page
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

          allow :'D', :user_level => :editor
          allow :'C', :user_level => :root
        end

        box :admin_level, :user_level => :admin do
          field :editor_level, :user_level => :editor
          field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'C', :user_level => :admin
          allow :'D', :user_level => :root
        end

        box :root_level, :user_level => :root do
          field :editor_level, :user_level => :editor
          field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'C', :user_level => :root
        end

        box :mixed_level, :read_level => :editor, :write_level => :root do
          field :editor_level, :user_level => :editor
          field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'C', :user_level => :editor
        end

        box :default_level do
          field :editor_level, :user_level => :editor
          field :admin_level, :user_level => :admin
          field :root_level, :user_level => :root
          field :mixed_level, :read_level => :editor, :write_level => :root
          field :default_level

          allow :'C'
        end
      end
      Content.delete
      Permissions::User.delete
      Permissions::AccessKey.delete
      Spontaneous.environment = :test
      Permissions::UserLevel.reset!
      Permissions::UserLevel.stubs(:level_file).returns(File.expand_path('../../fixtures/permissions', __FILE__) / 'config/user_levels.yml')

      ::Content.scope do
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
    end

    after do
      [:C, :D, :SitePage].each { |k| Object.send(:remove_const, k) rescue nil }
      Content.delete
      Permissions::User.delete
      Permissions::AccessKey.delete
    end

    describe "Unauthorised sessions" do
      it "redirect / to /@spontaneous" do
        get "/"
        assert last_response.status == 302
        last_response.headers["Location"].must_match %r{/@spontaneous$}
      end

      it "redirect /* to /@spontaneous" do
        get "/about"
        assert last_response.status == 302
        last_response.headers["Location"].must_match %r{/@spontaneous$}
      end

      it "see a login page at /@spontaneous" do
        get "/@spontaneous"
        assert_login_page
      end

      it "see a login page for all GETs" do
        get_paths.split.each do |path|
          get "/@spontaneous#{path}"
          assert_login_page path
        end
      end

      it "see a login page for all POSTs" do
        post_paths.split.each do |path|
          post "/@spontaneous#{path}"
          assert_login_page(path, "POST")
        end
      end

      it "get access to static files" do
        get "/@spontaneous/static/favicon.ico"
        assert last_response.status == 200
      end

      it "get access to Javascript files" do
        get "/@spontaneous/js/init.js"
        assert last_response.status == 200
      end

      it "get access to CSS files" do
        get "/@spontaneous/css/spontaneous.css"
        assert last_response.status == 200
      end

      it "get access to media files" do
        get '/media/image.jpg'
        assert last_response.status == 200
      end

      it "has access to the unsupported browser page" do
        get '/@spontaneous/unsupported'
        assert last_response.status == 200
      end

      describe "Logging in" do
        it "fail unless provided with a login & password" do
          post "/@spontaneous/login", "user[login]" => "", "user[password]" => ""
          assert_login_page("/@spontaneous/login", "POST")
        end

        it "fail for invalid login names" do
          post "/@spontaneous/login", "user[login]" => "noone", "user[password]" => "wrong"
          assert_login_page("/@spontaneous/login", "POST")
        end

        it "fail for invalid passwords" do
          post "/@spontaneous/login", "user[login]" => "editor", "user[password]" => "wrong"
          assert_login_page("/@spontaneous/login", "POST")
        end

        it "fail for disabled users" do
          post "/@spontaneous/login", "user[login]" => "disabled", "user[password]" => "disabled_password"
          assert_login_page("/@spontaneous/login", "POST")
        end

        it "succeed and redirect to /@spontaneous for correct login & password" do
          # post "/@spontaneous/login", "user[login]" => "admin", "user[password]" => "admin_password"
          login_user(@admin_user, "origin" => "/103/preview")
          assert last_response.status == 302, "Status was #{last_response.status} not 302"
          last_response.headers["Location"].must_match %r{/@spontaneous/103/preview$}
        end

        it "set the secure flag for cookies delivered behind https" do
          clear_cookies
          rack_mock_session.cookie_jar[S::Rack::AUTH_COOKIE].must_be_nil
          user = @admin_user
          post "https://example.org/@spontaneous/login", {"user[login]" => user.login, "user[password]" => user.password}
          cookies = rack_mock_session.cookie_jar.instance_variable_get("@cookies")
          cookie = cookies.detect { |c| c.name == S::Rack::AUTH_COOKIE }
          assert cookie.secure?
        end

        it "succeed and return an api key value for correct login over XHR" do
          key = Spontaneous::Permissions::AccessKey.new
          Spontaneous::Permissions::AccessKey.expects(:new).returns(key)
          post "/@spontaneous/login", { "user[login]" => "admin", "user[password]" => "admin_password" }, {"HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
          assert last_response.status == 200, "Status was #{last_response.status} not 200"
          result = Spot::JSON.parse(last_response.body)
          result[:key].must_equal key.key_id
          result[:redirect].must_equal "/@spontaneous"
        end
      end

    end

    describe "Invalid access keys" do
      before do
        login_user(@editor_user)
        @valid_key = rack_mock_session.cookie_jar[S::Rack::AUTH_COOKIE]
        S::Permissions::AccessKey.expects(:authenticate).with(@valid_key, anything).returns(nil)
      end

      it "should show a login page" do
        get '/@spontaneous'
        assert_login_page
      end
    end

    describe "Logged in users" do
      before do
        login_user(@editor_user)
      end

      after do
        clear_cookies
      end

      it "sets a long-lived cookie" do
        cookies = rack_mock_session.cookie_jar.instance_variable_get("@cookies")
        cookie = cookies.detect { |c| c.name == S::Rack::AUTH_COOKIE }
        expiry = cookie.expires
        expiry.must_be_instance_of Time
        expiry.must_be_close_to Time.now + S::Rack::SESSION_LIFETIME, 1
      end

      it "are provided with a CSRF token" do
        auth_get "/@spontaneous"
        assert last_response.ok?
        assert_contains_csrf_token @user.access_keys.first
      end

      it "need to supply CSRF header for all POSTs" do
        post_paths.split.delete_if { |path| }.each do |path|
          post "/@spontaneous#{path}"
          assert last_response.status == 401, "Status was #{last_response.status} not 401"
        end
      end

      it "need to supply CSRF header for all GETs" do
        get_paths.split.each do |path|
          get "/@spontaneous#{path}"
          assert last_response.status == 401, "Status was #{last_response.status} not 401"
        end
      end

      it "can supply the CSRF token as a URL parameter xxx" do
        get_paths.split.each do |path|
          get "/@spontaneous/site?#{S::Rack::CSRF_PARAM}=#{api_key.generate_csrf_token}"
          assert last_response.status == 200, "Status was #{last_response.status} not 401"
        end
      end

      it "be able to view the preview" do
        get "/"
        assert last_response.ok?
      end

      it "be able to view the editing interface" do
        get "/@spontaneous"
        assert last_response.ok?, "Expected 200 but got #{last_response.status}"
      end

      it "be able to logout" do
        auth_post "/@spontaneous/logout"
        assert last_response.status == 401
        rack_mock_session.cookie_jar.merge(last_response.headers["set-cookie"])
        rack_mock_session.cookie_jar[Spontaneous::Rack::AUTH_COOKIE].value.must_equal ""
      end
    end
    describe "User levels" do
      describe "Root access" do
        before do
          login_user(@root_user)
        end

        after do
          clear_cookies
        end

        it "be able to update root level fields" do
          field = root.fields.root_level
          auth_put "/@spontaneous/content/#{root.id}", "field[#{field.schema_id}]" => "Updated"
          assert last_response.ok?
          root.reload.fields[:root_level].value.must_equal "Updated"
        end

        it "be able to add to root level box" do
          klass = C
          auth_post "/@spontaneous/content/#{root.id}/#{root.boxes[:root_level].schema_id}/#{klass.schema_id}"
          assert last_response.ok?
        end
      end
      describe "Admin access" do
        before do
          @root_copy = root
          login_user(@admin_user)
        end

        after do
          clear_cookies
        end

        # DISABLED: The ui should ensure that forbidden fields don't appear
        # the async update system simply ignores fields that the user can't
        # modify (see test_fields.rb).
        # should "not be able to update root level fields" do
        #   value = "Updated #{version}"
        #   field = root.fields[:root_level]
        #   auth_post "/@spontaneous/save/#{root.id}", "field[#{field.schema_id}]" => value
        #   assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        #   root.reload.fields[:root_level].value.must_equal @root_copy.root_level.value
        # end

        # should "not be able to update root level fields from admin level box" do
        #   value = "Updated #{version}"
        #   field = root.boxes[:admin_level].fields[:root_level]
        #   auth_post "/@spontaneous/savebox/#{root.id}/#{root.boxes[:admin_level].schema_id}", "field[#{field.schema_id}]" => value
        #   assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        # end

        it "be able to update admin level fields" do
          value = "Updated #{version}"
          field = root.fields[:admin_level]
          auth_put "/@spontaneous/content/#{root.id}", "field[#{field.schema_id}]" => value
          assert last_response.ok?
          root.reload.fields[:admin_level].value.must_equal value
        end

        it "not be able to add to root level box" do
          auth_post "/@spontaneous/content/#{root.id}/#{root.boxes[:root_level].schema_id}/#{C.schema_id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        it "not be able to add root level types to admin level box" do
          auth_post "/@spontaneous/content/#{root.id}/#{root.boxes[:admin_level].schema_id}/#{D.schema_id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        it "be able to add to admin level box" do
          auth_post "/@spontaneous/content/#{root.id}/#{root.boxes[:admin_level].schema_id}/#{C.schema_id}"
          # post "/@spontaneous/add/#{root.id}/admin_level/C"
          assert last_response.ok?
        end

        it "not be able to update fields from root level box" do
          value = "Updated #{version}"
          field = root.fields[:editor_level]
          auth_put "/@spontaneous/content/#{root.id}/#{root.boxes[:root_level].schema_id}", "field[#{field.schema_id}]" => value
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        it "not be able to delete from root level box" do
          piece = root.boxes[:root_level].contents.first
          pieces = root.reload.boxes[:root_level].contents.length
          auth_delete "/@spontaneous/content/#{piece.id}"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
          root.reload.boxes[:root_level].contents.length.must_equal pieces
        end
        it "not be able to wrap files in root level box" do
          src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
          auth_post "/@spontaneous/file/#{root.id}/#{root.boxes[:root_level].schema_id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg")
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end
        it "not be able to wrap files in box if allow permissions don't permit it" do
          src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
          # only type with an image field is C
          # editor_level box allows addition of type C but only by root
          # so the following should throw a perms error:
          auth_post "/@spontaneous/file/#{root.id}/#{root.boxes[:editor_level].schema_id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg")
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end
        it "not be able to re-order pieces in root level box" do
          piece = root.boxes[:root_level].contents.last
          auth_patch "/@spontaneous/content/#{piece.id}/position/0"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
          root.reload.boxes[:root_level].contents.last.id.must_equal piece.id
        end

        it "not be able to replace root level fields" do
          piece = root.boxes[:root_level].contents.first
          src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
          field = piece.fields[:photo]
          auth_put "/@spontaneous/file/#{piece.id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg"), "field" => field.schema_id
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        it "not be able to hide entries in root-level boxes" do
          piece = root.boxes[:root_level].contents.first
          auth_patch "/@spontaneous/content/#{piece.id}/toggle"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end

        it "not be allowed to update path of pages without permission"
      end
      describe "Editor access" do
        before do
          @root_copy = root
          login_user(@editor_user)
        end

        after do
          clear_cookies
        end

        it "not be able to retrieve the list of changes" do
          auth_get "/@spontaneous/changes"
          assert last_response.status == 403, "Should have a permissions error 403 not #{last_response.status}"
        end
      end
    end

  end
end

