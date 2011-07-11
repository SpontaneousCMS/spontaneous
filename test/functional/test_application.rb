# encoding: UTF-8

require 'test_helper'

# set :environment, :test

class ApplicationTest < MiniTest::Spec
  include Spontaneous
  include ::Rack::Test::Methods

  def setup
    @saved_schema_root = Spontaneous.schema_root
    Spontaneous.schema_root = nil
    Spontaneous.root = File.expand_path("../../fixtures/example_application", __FILE__)
    File.exists?(Spontaneous.root).should be_true
  end

  def teardown
    # to keep other tests working
    Spontaneous.schema_root = @saved_schema_root
  end

  context "schema" do
    setup do
      Spontaneous.init(:mode => :back, :environment => :development)
    end

    should "load" do
      Object.const_get(:HomePage).must_be_instance_of(Class)
    end
  end

  context "Site" do
    should "have the same config as Spontaneous" do
      Site.config.should == Spontaneous.config
    end

    should "enable setting config vars on Site" do
      Site.config.butter = "yummy"
      Site.config.butter.should == "yummy"
    end
  end
  context "back, development" do

    setup do
      Spontaneous.init(:mode => :back, :environment => :development)
      Sequel::Migrator.apply(Spontaneous.database, 'db/migrations')
    end

    should "have the right mode setting" do
      Spontaneous.mode.should == :back
      Spontaneous.back?.should be_true
      Spontaneous.front?.should be_false
    end

    should "have the right env setting" do
      Spontaneous.environment.should == :development
      Spontaneous.env.should == :development
      Spontaneous.development?.should be_true
      Spontaneous.production?.should be_false
    end
    should "have correct config dir" do
      Spontaneous.config_dir.should == Spontaneous.root / "config"
    end

    should "have correct schema dir" do
      Spontaneous.schema_root.should == Spontaneous.root / "schema"
    end

    should "have correct db settings" do
      Spontaneous.config.db[:adapter].should == "mysql2"
      Spontaneous.config.db[:database].should == "spontaneous2_test"
      Spontaneous.config.db[:user].should == "root"
      Spontaneous.config.db[:password].should be_nil
      Spontaneous.config.db[:host].should == "localhost"
    end

    should "configure the datamapper connection" do
      db = Spontaneous.database
      db.adapter_scheme.should == :mysql2
      # opts.should == {"username"=>"spontaneous", "adapter"=>"mysql", "database"=>"spontaneous_example", "host"=>"localhost", "password"=>"password"}
    end

    should "have the right rack application" do
      # Spontaneous::Rack.application.should == Spontaneous::Rack::Back.application
    end
    should "have the right rack port" do
      Spontaneous::Rack.port.should == 9001
    end
    # should "have the right rack config file" do
    #   Spontaneous::Rack.config_file.should == Spontaneous.root / ""
    # end
  end

  context "front, development" do

    setup do
      Spontaneous.init(:mode => :front, :environment => :development)
    end

    should "have the right mode setting" do
      Spontaneous.mode.should == :front
      Spontaneous.back?.should be_false
      Spontaneous.front?.should be_true
    end

    should "have the right env setting" do
      Spontaneous.environment.should == :development
    end

    should "have the right rack application" do
      # Spontaneous::Rack.application.should == Spontaneous::Rack::Front.application
    end
    should "have the right rack port" do
      Spontaneous::Rack.port.should == 9002
    end
  end

  context "back, production" do
    setup do
      Spontaneous.init(:mode => :back, :environment => :production)
    end

    should "have the right mode setting" do
      Spontaneous.mode.should == :back
      Spontaneous.back?.should be_true
      Spontaneous.front?.should be_false
    end

    should "have the right env setting" do
      Spontaneous.environment.should == :production
      Spontaneous.development?.should be_false
      Spontaneous.production?.should be_true
      # Spontaneous.config.environment.should == :production
    end

    should "have correct db settings" do
      Spontaneous.config.db[:adapter].should == "mysql2"
      Spontaneous.config.db[:database].should == "spontaneous_example_production"
      Spontaneous.config.db[:user].should == "spontaneous_prod"
      Spontaneous.config.db[:password].should == "Passw0rd"
      Spontaneous.config.db[:host].should == "localhost"
    end

    should "have the right rack port" do
      Spontaneous::Rack.port.should == 3001
    end
  end

  context "front, production" do

    setup do
      Spontaneous.init(:mode => :front, :environment => :production)
    end

    should "have the right mode setting" do
      Spontaneous.mode.should == :front
      Spontaneous.back?.should be_false
      Spontaneous.front?.should be_true
    end

    should "have the right env setting" do
      Spontaneous.environment.should == :production
      Spontaneous.development?.should be_false
      Spontaneous.production?.should be_true
    end

    should "have the right rack port" do
      Spontaneous::Rack.port.should == 3002
    end
  end
end

