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
    [:Page, :Piece, :Project, :ProjectImage, :ProjectsPage, :Text, :HomePage, :InfoPage, :ClientProject, :ClientProjects, :InlineImage].each do |klass|
      Object.send :remove_const, klass rescue nil
    end
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
      @site = Spontaneous.init(:root => site_root, :mode => :back, :environment => :development)
    end

    it "returns an instance of the site from Spontaneous.init" do
      @site.must_be_instance_of Spontaneous::Site
    end

    it "have the same config as Spontaneous" do
      @site.config.must_equal Spontaneous.config
    end

    it "enable setting config vars on Site" do
      @site.config.butter = "yummy"
      @site.config.butter.must_equal "yummy"
    end
  end


  describe "initializers" do
    it "all run" do
      defined?(INITIALIZER1_RUN).must_equal "constant"
      INITIALIZER1_RUN.must_equal true
      defined?(INITIALIZER2_RUN).must_equal "constant"
      INITIALIZER2_RUN.must_equal true
    end
  end

  describe "back, development" do

    before do
      @site = Spontaneous.init(:root => site_root, :mode => :back, :environment => :development)
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
      @site.config.db[:adapter].must_equal "postgres"
      @site.config.db[:database].must_equal "spontaneous2_test"
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
      @site = Spontaneous.init(:root => site_root, :mode => :back, :environment => :production)
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
      @site.config.db[:adapter].must_equal "postgres"
      @site.config.db[:database].must_equal "spontaneous_example_production"
      @site.config.db[:user].must_equal "spontaneous_prod"
      @site.config.db[:password].must_equal "Passw0rd"
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

  describe 'ENV["DATABASE_URL"]' do
    before do
      ENV['DATABASE_URL'] = 'sqlite:///production.db'
      @site = Spontaneous.init(:root => site_root, :mode => :front, :environment => :production)
    end

    after do
      ENV.delete('DATABASE_URL')
    end

    it 'should override settings in database.yml' do
      @site.config.db.must_equal 'sqlite:///production.db'
    end
  end
end
