# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

require 'sinatra/base'

class FeaturesTest < MiniTest::Spec
  include ::Rack::Test::Methods

  def self.startup
    # make sure that S::Piece & S::Page are removed from the schema
    @site = setup_site
    *ids = S::Page.schema_id, S::Piece.schema_id
    Object.const_set(:Site, Class.new(S::Site))
  end

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  def app
    Spontaneous::Rack.application
  end

  def auth_post(path, params={})
    post(path, params.merge("__key" => @key))
  end

  def auth_get(path, params={})
    get(path, params.merge("__key" => @key))
  end

  context "Feature" do
    setup do
      Content.delete
      Spontaneous::Permissions::User.delete


      config = mock()
      config.stubs(:reload_classes).returns(false)
      config.stubs(:auto_login).returns('root')
      config.stubs(:default_charset).returns('utf-8')
      config.stubs(:publishing_method).returns(:immediate)
      config.stubs(:site_domain).returns('example.org')
      config.stubs(:site_id).returns('example_org')
      @site.stubs(:config).returns(config)

      @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass")
      @user.update(:level => Spontaneous::Permissions.root)
      @user.save
      @key = "c5AMX3r5kMHX2z9a5ExLKjAmCcnT6PFf22YQxzb4Codj"
      @key.stubs(:user).returns(@user)

      Spontaneous::Permissions::User.stubs(:[]).with(:login => 'root').returns(@user)
      Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(@key).returns(@key)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(nil, nil).returns(false)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(nil, @user).returns(false)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(@key, @user).returns(true)
    end

    teardown do
      # (@all_classes.map { |k| k.name.to_sym }).each { |klass|
      #   Object.send(:remove_const, klass) rescue nil
      # } rescue nil
      Content.delete
    end

    context "controllers" do
      setup do
        class ::FeatureBackController < ::Sinatra::Base
          get '/hello' do
            'Editor'
          end
          post '/goodbye' do
            'Cruel Editor'
          end
        end
        class ::FeatureFrontController < ::Sinatra::Base
          get '/hello' do
            'World'
          end
          post '/goodbye' do
            'Cruel World'
          end
        end
      end

      teardown do
        Object.send(:remove_const, :FeatureBackController) rescue nil
        Object.send(:remove_const, :FeatureFrontController) rescue nil
      end

      should "be able to injectable into the back application" do
        Spontaneous.mode = :back
        Spontaneous.register_back_controller(:myfeature, FeatureBackController)

        get "/@myfeature/hello"
        assert last_response.status == 401, "Expected an Unauthorised 401 response but got #{last_response.status}"

        auth_get "/@myfeature/hello"
        assert last_response.ok?
        assert last_response.body == "Editor"

        post "/@myfeature/goodbye"
        assert last_response.status == 401

        auth_post "/@myfeature/goodbye"
        assert last_response.ok?
        assert last_response.body == "Cruel Editor"
      end

      should "be able to inject controllers into the front application" do
        Spontaneous.mode = :front
        Spontaneous.register_front_controller(:myfeature, FeatureFrontController)
        get "/@myfeature/hello"
        assert last_response.ok?
        assert last_response.body == "World"

        post "/@myfeature/goodbye"
        assert last_response.ok?
        assert last_response.body == "Cruel World"
      end
    end
  end
end
