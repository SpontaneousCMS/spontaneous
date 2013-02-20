# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Config" do
  # include CustomMatchers

  before do
    @site = setup_site
    @config_dir = File.expand_path("../../fixtures/config/config", __FILE__)

    class ::TopLevel
      def self.parameter=(something)
        @parameter = something
      end

      def self.parameter
        @parameter
      end
    end
  end

  after do
    Object.send(:remove_const, :TopLevel) rescue nil
    teardown_site
  end


  describe "initialization" do
    before do
      @config = Spontaneous::Config.new(:development)
      @config.load(@config_dir)
    end
    it "load the first time its accessed" do
      @config.over_ridden.must_equal :development_value
    end
  end

  describe "containing blocks" do
    before do
      @settings = {}
      @config = Spontaneous::Config::Loader.new(@settings)
    end
    it "add a hash to the settings under the defined key" do
      @config.storage :key1 do |config|
        config[:a] = "a"
        config[:b] = "b"
      end
      @config.storage :key2 do |config|
        config[:c] = "c"
        config[:d] = "d"
      end
      @config.storage :key1 do |config|
        config[:e] = "e"
      end
      @config.settings[:storage].must_equal({
        :key1 => { :a => "a", :b => "b", :e => "e" },
        :key2 => { :c => "c", :d => "d" }
      })
    end
  end
  describe "Independent configuration loading" do
    before do
      @config = Spontaneous::Config.new(:development)
      @config.load(@config_dir)
    end

    after do
    end

    it "be run from application dir" do
      assert File.exist?('config')
    end

    it "read from the global environment file" do
      @config.some_configuration.must_equal [:some, :values]
    end

    it "initialise in development mode" do
      @config.environment.must_equal :development
    end

    # it "allow setting of environment" do
    #   Config.environment.must_equal :development
    #   Config.environment = :production
    #   Config.environment.must_equal :production
    # end

    it "overwrite values depending on environment" do
      @config.over_ridden.must_equal :development_value
      config = Spontaneous::Config.new(:production)
      config.load(@config_dir)
      config.over_ridden.must_equal :production_value
      config = Spontaneous::Config.new(:staging)
      config.load(@config_dir)
      config.over_ridden.must_equal :environment_value
    end

    it "allow setting of env values" do
      @config.something_else.must_be_nil
      @config[:something_else] = "loud"
      @config.something_else.must_equal "loud"
    end

    it "allow setting of env values through method calls" do
      @config.something_else2.must_be_nil
      @config.something_else2 = "loud"
      @config.something_else2.must_equal "loud"
    end

    it "dynamically switch values according to the configured env" do
      @config.over_ridden.must_equal :development_value
      config = Spontaneous::Config.new(:production)
      config.load(@config_dir)
      config.over_ridden.must_equal :production_value
      config = Spontaneous::Config.new(:staging)
      config.load(@config_dir)
      config.over_ridden.must_equal :environment_value
    end

    it "allow local over-riding of settings" do
      @config.wobbling.must_be_nil
      @config.wobbling = "badly"
      @config.wobbling.must_equal "badly"
    end

    it "fallback to defaults" do
      @config.new_setting.must_be_nil
      @config.defaults[:new_setting] = "new setting"
      @config.new_setting.must_equal "new setting"
    end

    it "accept blocks/procs/lambdas as values" do
      fish = "flying"
      @config.useful_feature = Proc.new { fish }
      @config.useful_feature.must_equal "flying"
      @config.defaults[:new_dynamic_setting] = Proc.new { fish }
      @config.new_dynamic_setting.must_equal "flying"
    end

    it "allow calling of global methods" do
      TopLevel.parameter.must_equal :dev
    end

    describe "Spontaneous :back" do
      before do
        @config = Spontaneous::Config.new(:development, :back)
        @config.load(@config_dir)
      end
      it "read the correct configuration values" do
        @config.port.must_equal 9001
      end
    end
    describe "Spontaneous :front" do
      before do
        @config = Spontaneous::Config.new(:development, :front)
        @config.load(@config_dir)
      end
      it "read the correct configuration values" do
        @config.port.must_equal 9002
      end
    end
  end
end
