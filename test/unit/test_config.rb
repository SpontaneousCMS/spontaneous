# encoding: UTF-8

require 'test_helper'

class ConfigTest < MiniTest::Spec
  include CustomMatchers
  def setup
  end

  context "Config" do
    setup do
      Config = ::Spontaneous::Config
      @lib_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../../../../lib'))
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
      self.class.send(:remove_const, :Config) rescue nil
    end

    context "Config" do
      setup do
      end
      should "load the first time its accessed" do
        Config.over_ridden.should == :development_value
      end
    end

    context "Independent configuration loading" do
      setup do
        # defined?(Spontaneous).should be_nil
        # Object.send(:remove_const, :Spontaneous) rescue nil
        # defined?(Spontaneous).should be_nil
        # require @lib_dir + '/spontaneous/config.rb'
        # Config.environment = :development
        Config.load(:development)
      end

      teardown do
      end

      should "be run from application dir" do
        File.exist?('config').should be_true
      end

      should "read from the global environment file" do
        Config.some_configuration.should == [:some, :values]
      end

      should "initialise in development mode" do
        Config.environment.should == :development
      end

      # should "allow setting of environment" do
      #   Config.environment.should == :development
      #   Config.environment = :production
      #   Config.environment.should == :production
      # end

      should "overwrite values depending on environment" do
        Config.over_ridden.should == :development_value
        Config.load(:production)
        Config.over_ridden.should == :production_value
        Config.load(:staging)
        Config.over_ridden.should == :environment_value
      end

      should "allow setting of env values" do
        Config.something_else.should be_nil
        Config[:something_else] = "loud"
        Config.something_else.should == "loud"
      end

      should "allow setting of env values through method calls" do
        Config.something_else2.should be_nil
        Config.something_else2 = "loud"
        Config.something_else2.should == "loud"
      end

      should "dynamically switch values according to the configured env" do
        Config.over_ridden.should == :development_value
        Config.environment = :production
        Config.over_ridden.should == :production_value
        Config.environment = :staging
        Config.over_ridden.should == :environment_value
      end

      should "allow local over-riding of settings" do
        Config.wobbling.should be_nil
        Config.wobbling = "badly"
        Config.wobbling.should == "badly"
      end

      should "fallback to defaults" do
        Config.new_setting.should be_nil
        Config.defaults[:new_setting] = "new setting"
        Config.new_setting.should == "new setting"
      end

      should "accept blocks/procs/lambdas as values" do
        fish = "flying"
        Config.useful_feature = Proc.new { fish }
        Config.useful_feature.should == "flying"
        Config.defaults[:new_dynamic_setting] = Proc.new { fish }
        Config.new_dynamic_setting.should == "flying"
      end

      should "allow calling of global methods" do
        TopLevel.parameter.should == :dev
      end

      teardown do
        Dir.chdir(@pwd)
      end
      context "Spontaneous :back" do
        setup do
          Spontaneous.mode = :back
          Config.load(:development)
        end
        should "read the correct configuration values" do
          Config.port.should == 9001
        end
      end
      context "Spontaneous :front" do
        setup do
          Spontaneous.mode = :front
          Config.load
        end
        should "read the correct configuration values" do
          Config.port.should == 9002
        end
      end
    end
  end
end
