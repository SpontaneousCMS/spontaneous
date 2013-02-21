# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# set :environment, :test

describe "Application" do
  include Spontaneous

  start do
    site_root = Dir.mktmpdir
    app_root = File.expand_path('../../fixtures/example_application', __FILE__)
    FileUtils.cp_r(app_root, site_root)
    site_root += "/example_application"
    # Force loading of model in dev mode (where we have a db to introspect)
    Spontaneous.init(:root => site_root, :mode => :back, :environment => :development)
    let(:site_root) { site_root }
  end

  finish do
    Object.send :remove_const, :Page
    Object.send :remove_const, :Piece
    Object.send :remove_const, :Project
    Object.send :remove_const, :ProjectImage
    Object.send :remove_const, :ProjectsPage
    Object.send :remove_const, :Text
    Object.send :remove_const, :HomePage
    Object.send :remove_const, :InfoPage
    Object.send :remove_const, :ClientProject
    Object.send :remove_const, :ClientProjects
    Object.send :remove_const, :InlineImage

    teardown_site(true)
  end

  before do
  end

  describe "schema" do
    before do
      Spontaneous.init(:root => site_root, :mode => :back, :environment => :development)
    end

    it "load" do
      Object.const_get(:HomePage).must_be_instance_of(Class)
    end
  end

  describe "Site" do
    before do
      Spontaneous.init(:root => site_root, :mode => :back, :environment => :development)
    end
    it "have the same config as Spontaneous" do
      Site.config.must_equal Spontaneous.config
    end

    it "enable setting config vars on Site" do
      Site.config.butter = "yummy"
      Site.config.butter.must_equal "yummy"
    end
  end

  describe "back, development" do

    before do
      Spontaneous.init(:root => site_root, :mode => :back, :environment => :development)
      Sequel::Migrator.apply(Spontaneous.database, 'db/migrations')
    end

    it "have the right mode setting" do
      Spontaneous.mode.must_equal :back
      assert Spontaneous.back?
      refute Spontaneous.front?
    end

    it "have the right env setting" do
      Spontaneous.environment.must_equal :development
      Spontaneous.env.must_equal :development
      assert Spontaneous.development?
      refute Spontaneous.production?
    end
    it "have correct config dir" do
      Spontaneous.config_dir.must_equal Spontaneous.root / "config"
    end

    it "have correct schema dir" do
      Spontaneous.schema_root.must_equal Spontaneous.root / "schema"
    end

    it "have correct db settings" do
      Site.config.db[:adapter].must_equal "postgres"
      Site.config.db[:database].must_equal "spontaneous2_test"
      # Site.config.db[:user].must_equal "root"
      # Site.config.db[:password].should be_nil
      # Site.config.db[:host].must_equal "localhost"
    end

    it "configure the datamapper connection" do
      db = Spontaneous.database
      db.adapter_scheme.must_equal :postgres
      # opts.must_equal {"username"=>"spontaneous", "adapter"=>"mysql", "database"=>"spontaneous_example", "host"=>"localhost", "password"=>"password"}
    end

    it "have the right rack application" do
      # Spontaneous::Rack.application.must_equal Spontaneous::Rack::Back.application
    end
    it "have the right rack port" do
      Spontaneous::Rack.port.must_equal 9001
    end
    # it "have the right rack config file" do
    #   Spontaneous::Rack.config_file.must_equal Spontaneous.root / ""
    # end
  end

  describe "front, development" do

    before do
      Spontaneous.init(:root => site_root, :mode => :front, :environment => :development)
      Sequel::Migrator.apply(Spontaneous.database, 'db/migrations')
    end

    it "have the right mode setting" do
      Spontaneous.mode.must_equal :front
      refute Spontaneous.back?
      assert Spontaneous.front?
    end

    it "have the right env setting" do
      Spontaneous.environment.must_equal :development
    end

    it "have the right rack application" do
      # Spontaneous::Rack.application.must_equal Spontaneous::Rack::Front.application
    end
    it "have the right rack port" do
      Spontaneous::Rack.port.must_equal 9002
    end
  end

  describe "back, production" do
    before do
      Spontaneous.init(:root => site_root, :mode => :back, :environment => :production)
    end

    it "have the right mode setting" do
      Spontaneous.mode.must_equal :back
      assert Spontaneous.back?
      refute Spontaneous.front?
    end

    it "have the right env setting" do
      Spontaneous.environment.must_equal :production
      refute Spontaneous.development?
      assert Spontaneous.production?
      # Site.config.environment.must_equal :production
    end

    it "have correct db settings" do
      Site.config.db[:adapter].must_equal "postgres"
      Site.config.db[:database].must_equal "spontaneous_example_production"
      Site.config.db[:user].must_equal "spontaneous_prod"
      Site.config.db[:password].must_equal "Passw0rd"
      # Site.config.db[:host].must_equal "localhost"
    end

    it "have the right rack port" do
      Spontaneous::Rack.port.must_equal 3001
    end
  end

  describe "front, production" do

    before do
      Spontaneous.init(:root => site_root, :mode => :front, :environment => :production)
    end

    it "have the right mode setting" do
      Spontaneous.mode.must_equal :front
      refute Spontaneous.back?
      assert Spontaneous.front?
    end

    it "have the right env setting" do
      Spontaneous.environment.must_equal :production
      refute Spontaneous.development?
      assert Spontaneous.production?
    end

    it "have the right rack port" do
      Spontaneous::Rack.port.must_equal 3002
    end
  end
end
