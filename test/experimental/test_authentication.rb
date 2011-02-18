# encoding: UTF-8

require 'test_helper'

# set :environment, :test


class AuthenticationTest < Test::Unit::TestCase
  include StartupShutdown
  include ::Rack::Test::Methods

  class C < Spontaneous::Piece; end
  class D < Spontaneous::Piece; end

  class SitePage < Spontaneous::Page
    page_style :default
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
      allow :'AuthenticationTest::C', :user_level => :admin
    end

    box :admin_level, :user_level => :admin do
      field :editor_level, :user_level => :editor
      field :admin_level, :user_level => :admin
      field :root_level, :user_level => :root
      field :mixed_level, :read_level => :editor, :write_level => :root
      field :default_level

      allow :'AuthenticationTest::C', :user_level => :admin
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

  def self.startup
    Content.delete
    Spontaneous.environment = :test

    @saved_root = Spontaneous.root
    Spontaneous.root = File.expand_path('../../fixtures/example_application', __FILE__)

    Spontaneous.template_root = File.expand_path("../../fixtures/public/templates", __FILE__)

    @@root = SitePage.create
    @@root.save

    @@about = SitePage.create(:uid => 'about', :slug => "about")
    @@root.pages << @@about
    @@root.save

  end

  def self.shutdown
    Content.delete
    Spontaneous.root = @saved_root
  end

  def app
    Spontaneous::Rack::Back.application
  end

  def root
    @@root
  end

  def about
    @@about
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
      %(/save/#{root.id} /savebox/#{root.id}/editor_level /content/#{root.id}/position/0 /file/upload/#{root.id} /file/replace/#{root.id} /file/wrap/#{root.id}/pages /add/#{root.id}/pages/SitePage /destroy/#{root.id} /slug/#{root.id} /slug/#{root.id}/unavailable).split.each do |path|
        post "/@spontaneous#{path}"
        assert_login_page(path, "POST")
      end
    end

  end
end
