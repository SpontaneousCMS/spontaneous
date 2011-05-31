# encoding: UTF-8

require 'test_helper'

# set :environment, :test


class AuthenticationTest < MiniTest::Spec
  include ::Rack::Test::Methods


  def self.startup
  end

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

  def self.shutdown
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

  def setup
    # see http://benprew.posterous.com/testing-sessions-with-sinatra
    app.send(:set, :sessions, false)
    Spontaneous.media_dir = File.expand_path('../../fixtures/permissions/media', __FILE__)
  end

  def assert_login_page(path = nil, method = "GET")
    assert last_response.status == 401, "#{method} #{path} should have status 401 but has #{last_response.status}"
    last_response.body.should =~ %r{<form.+action="/@spontaneous/login"}
    last_response.body.should =~ %r{<form.+method="post"}
    last_response.body.should =~ %r{<input.+name="user\[login\]"}
    last_response.body.should =~ %r{<input.+name="user\[password\]"}
  end

  context "Authentication:" do
    setup do
      Spontaneous::Schema.reset!

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
      Permissions::UserLevel.level_file = File.expand_path('../../fixtures/permissions', __FILE__) / 'config/user_levels.yml'

      @saved_root = Spontaneous.root
      Spontaneous.root = File.expand_path('../../fixtures/example_application', __FILE__)

      Spontaneous.template_root = File.expand_path("../../fixtures/public/templates", __FILE__)

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
      [:C, :D, :SitePage].each { |k| AuthenticationTest.send(:remove_const, k)}
      Content.delete
      Permissions::User.delete
      Permissions::AccessKey.delete
      Spontaneous.root = @saved_root
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
        %(/root /page/#{root.id} /types /map /map/#{root.id} /location/about).split.each do |path|
          get "/@spontaneous#{path}"
          assert_login_page path
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

      should "see a login page for all POSTs" do
        %(/save/#{root.id} /savebox/#{root.id}/editor_level /content/#{root.id}/position/0 /file/upload/#{root.id} /file/replace/#{root.id} /file/wrap/#{root.id}/pages /add/#{root.id}/pages/SitePage /destroy/#{root.id} /slug/#{root.id} /slug/#{root.id}/unavailable /toggle/#{root.id}).split.each do |path|
          post "/@spontaneous#{path}"
          assert_login_page(path, "POST")
        end
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
          post "/@spontaneous/login", "user[login]" => "admin", "user[password]" => "admin_password"
          assert last_response.status == 302, "Status was #{last_response.status} not 302"
          last_response.headers["Location"].should =~ %r{/@spontaneous$}
        end
      end

      context "Logged in users" do
        setup do
          post "/@spontaneous/login", "user[login]" => "editor", "user[password]" => "editor_password"
        end

        teardown do
          clear_cookies
        end

        should "be able to view the preview" do
          get "/"
          assert last_response.ok?
        end

        should "be able to see previously forbidden fruit" do
          get "/@spontaneous/root"
          assert last_response.ok?
        end
      end

      context "User levels" do
        context "Root access" do
          setup do
            post "/@spontaneous/login", "user[login]" => "root", "user[password]" => "root_password"
          end

          teardown do
            clear_cookies
          end

          should "be able to update root level fields" do
            post "/@spontaneous/save/#{root.id}", 'field[root_level][unprocessed_value]' => "Updated"
            assert last_response.ok?
            root.reload.fields[:root_level].value.should == "Updated"
          end

          should "be able to add to root level box" do
            post "/@spontaneous/add/#{root.id}/root_level/AuthenticationTest::C"
            assert last_response.ok?
          end
        end
        context "Admin access" do
          setup do
            @root_copy = root
            post "/@spontaneous/login", "user[login]" => "admin", "user[password]" => "admin_password"
          end

          teardown do
            clear_cookies
          end

          should "not be able to update root level fields" do
            value = "Updated #{version}"
            post "/@spontaneous/save/#{root.id}", 'field[root_level][unprocessed_value]' => value
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
            root.reload.fields[:root_level].value.should == @root_copy.root_level.value
          end

          should "be able to update admin level fields" do
            value = "Updated #{version}"
            post "/@spontaneous/save/#{root.id}", 'field[admin_level][unprocessed_value]' => value
            assert last_response.ok?
            root.reload.fields[:admin_level].value.should == value
          end

          should "not be able to add to root level box" do
            post "/@spontaneous/add/#{root.id}/root_level/AuthenticationTest::C"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end

          should "not be able to add root level types to admin level box" do
            post "/@spontaneous/add/#{root.id}/admin_level/AuthenticationTest::D"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end

          should "be able to add to admin level box" do
            post "/@spontaneous/add/#{root.id}/admin_level/AuthenticationTest::C"
            assert last_response.ok?
          end
          should "not be able to update fields from root level box" do
            value = "Updated #{version}"
            post "/@spontaneous/savebox/#{root.id}/root_level", 'field[editor_level][unprocessed_value]' => value
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end

          should "not be able to update root level fields from admin level box" do
            value = "Updated #{version}"
            post "/@spontaneous/savebox/#{root.id}/admin_level", 'field[root_level][unprocessed_value]' => value
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end

          should "not be able to delete from root level box" do
            piece = root.boxes[:root_level].pieces.first
            pieces = root.reload.boxes[:root_level].pieces.length
            post "/@spontaneous/destroy/#{piece.id}"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
            root.reload.boxes[:root_level].pieces.length.should == pieces
          end
          should "not be able to wrap files in root level box" do
            src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
            post "/@spontaneous/file/wrap/#{root.id}/root_level", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg")
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end
          should "not be able to wrap files in box if allow permissions don't permit it" do
            src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
            # only type with an image field is C
            # editor_level box allows addition of type C but only by root
            # so the following should throw a perms error:
            post "/@spontaneous/file/wrap/#{root.id}/editor_level", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg")
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end
          should "not be able to re-order pieces in root level box" do
            piece = root.boxes[:root_level].pieces.last
            post "/@spontaneous/content/#{piece.id}/position/0"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
            root.reload.boxes[:root_level].pieces.last.id.should == piece.id
          end

          should "not be able to replace root level fields" do
            piece = root.boxes[:root_level].pieces.first
            src_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
            post "/@spontaneous/file/replace/#{piece.id}", "file" => ::Rack::Test::UploadedFile.new(src_file, "image/jpeg"), "field" => "photo"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end

          should "not be able to hide entries in root-level boxes" do
            piece = root.boxes[:root_level].pieces.first
            post "/@spontaneous/toggle/#{piece.id}"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end

          should "not be allowed to update path of pages without permission"
        end
        context "Editor access" do
          setup do
            @root_copy = root
            post "/@spontaneous/login", "user[login]" => "editor", "user[password]" => "editor_password"
          end

          teardown do
            clear_cookies
          end

          should "not be able to retrieve the list of changes" do
            Change.delete
            get "/@spontaneous/publish/changes"
            assert last_response.status == 401, "Should have a permissions error 401 not #{last_response.status}"
          end
        end
      end

    end
  end
end

