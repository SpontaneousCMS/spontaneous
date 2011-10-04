# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class ConfigTest < MiniTest::Spec
  include CustomMatchers
  def setup
  end

  context "Config" do
    setup do
      # Spontaneous.send(:remove_const, :Config) rescue nil
      # @lib_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../lib'))
      # load @lib_dir + '/spontaneous/config.rb'
      Config ||= ::Spontaneous::Config
      @pwd = Dir.pwd
      Dir.chdir(File.expand_path("../../fixtures/config", __FILE__))
      Spontaneous.root = Dir.pwd
      class ::TopLevel
        def self.parameter=(something)
          @parameter = something
        end

        def self.parameter
          @parameter
        end
      end
    end
    teardown do
      Object.send(:remove_const, :TopLevel)
      Dir.chdir(@pwd)
      # self.class.send(:remove_const, :Config) rescue nil
    end

    context "Config" do
      setup do
        @config = Config.new(:development)
        @config.load(Spontaneous.root / 'config')
      end
      should "load the first time its accessed" do
        @config.over_ridden.should == :development_value
      end
    end

    context "Independent configuration loading" do
      setup do
        # defined?(Spontaneous).should be_nil
        # Object.send(:remove_const, :Spontaneous) rescue nil
        # defined?(Spontaneous).should be_nil
        # require @lib_dir + '/spontaneous/config.rb'
        # Config.environment = :development
        @config = Config.new(:development)
        @config.load(Spontaneous.root / 'config')
      end

      teardown do
      end

      should "be run from application dir" do
        File.exist?('config').should be_true
      end

      should "read from the global environment file" do
        @config.some_configuration.should == [:some, :values]
      end

      should "initialise in development mode" do
        @config.environment.should == :development
      end

      # should "allow setting of environment" do
      #   Config.environment.should == :development
      #   Config.environment = :production
      #   Config.environment.should == :production
      # end

      should "overwrite values depending on environment" do
        @config.over_ridden.should == :development_value
        config = Config.new(:production)
        config.load(Spontaneous.root / 'config')
        config.over_ridden.should == :production_value
        config = Config.new(:staging)
        config.load(Spontaneous.root / 'config')
        config.over_ridden.should == :environment_value
      end

      should "allow setting of env values" do
        @config.something_else.should be_nil
        @config[:something_else] = "loud"
        @config.something_else.should == "loud"
      end

      should "allow setting of env values through method calls" do
        @config.something_else2.should be_nil
        @config.something_else2 = "loud"
        @config.something_else2.should == "loud"
      end

      should "dynamically switch values according to the configured env" do
        @config.over_ridden.should == :development_value
        config = Config.new(:production)
        config.load(Spontaneous.root / 'config')
        config.over_ridden.should == :production_value
        config = Config.new(:staging)
        config.load(Spontaneous.root / 'config')
        config.over_ridden.should == :environment_value
      end

      should "allow local over-riding of settings" do
        @config.wobbling.should be_nil
        @config.wobbling = "badly"
        @config.wobbling.should == "badly"
      end

      should "fallback to defaults" do
        @config.new_setting.should be_nil
        @config.defaults[:new_setting] = "new setting"
        @config.new_setting.should == "new setting"
      end

      should "accept blocks/procs/lambdas as values" do
        fish = "flying"
        @config.useful_feature = Proc.new { fish }
        @config.useful_feature.should == "flying"
        @config.defaults[:new_dynamic_setting] = Proc.new { fish }
        @config.new_dynamic_setting.should == "flying"
      end

      should "allow calling of global methods" do
        TopLevel.parameter.should == :dev
      end

      teardown do
        Dir.chdir(@pwd)
      end
      context "Spontaneous :back" do
        setup do
          @config = Config.new(:development, :back)
          @config.load(Spontaneous.root / 'config')
        end
        should "read the correct configuration values" do
          @config.port.should == 9001
        end
      end
      context "Spontaneous :front" do
        setup do
          @config = Config.new(:development, :front)
          @config.load(Spontaneous.root / 'config')
        end
        should "read the correct configuration values" do
          @config.port.should == 9002
        end
      end
    end
  end
end
