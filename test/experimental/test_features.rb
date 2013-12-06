# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

require 'sinatra/base'

describe "Features" do
  include RackTestMethods

  before do
    @site = setup_site
  end

  after do
    teardown_site
  end

  def app
    Spontaneous::Rack.application
  end

  def api_key
    @key
  end

  describe "Feature" do
    before do
      Content.delete
      Spontaneous::Permissions::User.delete


      config = mock()
      config.stubs(:reload_classes).returns(false)
      config.stubs(:auto_login).returns('root')
      config.stubs(:default_charset).returns('utf-8')
      config.stubs(:publishing_method).returns(:immediate)
      config.stubs(:simultaneous_connection).returns("")
      config.stubs(:site_domain).returns('example.org')
      config.stubs(:site_id).returns('example_org')
      @site.stubs(:config).returns(config)

      @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass")
      @user.update(:level => Spontaneous::Permissions.root)
      @user.save
      @key = @user.generate_access_key("127.0.0.1")

      Spontaneous::Permissions::User.stubs(:[]).with(:login => 'root').returns(@user)
      Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(@key).returns(@key)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(nil, nil).returns(false)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(nil, @user).returns(false)
      Spontaneous::Permissions::AccessKey.stubs(:valid?).with(@key, @user).returns(true)
    end

    after do
      # (@all_classes.map { |k| k.name.to_sym }).each { |klass|
      #   Object.send(:remove_const, klass) rescue nil
      # } rescue nil
      Content.delete
    end

    describe "controllers" do
      before do
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

      after do
        Object.send(:remove_const, :FeatureBackController) rescue nil
        Object.send(:remove_const, :FeatureFrontController) rescue nil
      end

      it "be able to injectable into the back application" do
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

      it "be able to inject controllers into the front application" do
        Spontaneous.mode = :front
        Spontaneous.register_front_controller(:myfeature, FeatureFrontController)
        get "/@myfeature/hello"
        assert last_response.ok?
        assert last_response.body == "World"

        post "/@myfeature/goodbye"
        assert last_response.ok?
        assert last_response.body == "Cruel World"
      end

      it "allows injection of rack apps into the the back application" do
        Spontaneous.mode = :back
        Spontaneous.register_back_controller(:myfeature, proc { |env| [200, {}, "hello"] })

        get "/@myfeature"
        assert last_response.status == 401, "Expected an Unauthorised 401 response but got #{last_response.status}"

        auth_get "/@myfeature"
        assert last_response.ok?
        assert last_response.body == "hello"
      end
    end
  end
end
