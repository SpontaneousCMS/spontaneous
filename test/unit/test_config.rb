# encoding: UTF-8

require 'test_helper'

class ConfigTest < Test::Unit::TestCase
  include CustomMatchers
  context "Independent configuration loading" do
    setup do
      @pwd = Dir.pwd
      Config = ::Spontaneous::Config
      Dir.chdir(File.expand_path("../../fixtures/example_application", __FILE__))
      @lib_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../../../../lib'))
      # defined?(Spontaneous).should be_nil
      # Object.send(:remove_const, :Spontaneous) rescue nil
      # defined?(Spontaneous).should be_nil
      # require @lib_dir + '/spontaneous/config.rb'
      Config.load
      Config.environment = :development
    end

    teardown do
      self.class.send(:remove_const, :Config) rescue nil
      Dir.chdir(@pwd)
    end

    should "be run from application dir" do
      File.exist?('schema').should be_true
    end

    should "read from the global environment file" do
      Config.some_configuration.should == [:some, :values]
    end

    should "initialise in development mode" do
      Config.environment.should == :development
    end

    should "allow setting of environment" do
      Config.environment.should == :development
      Config.environment = :production
      Config.environment.should == :production
    end

    should "overwrite values depending on environment" do
      Config[:development].over_ridden.should == :development_value
      Config[:production].over_ridden.should == :production_value
      Config[:staging].over_ridden.should == :environment_value
    end

    should "allow setting of env values" do
      Config[:development].something_else.should be_nil
      Config[:development][:something_else] = "loud"
      Config[:development].something_else.should == "loud"
    end

    should "allow setting of env values through method calls" do
      Config[:development].something_else2.should be_nil
      Config[:development].something_else2 = "loud"
      Config[:development].something_else2.should == "loud"
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

    teardown do
      Dir.chdir(@pwd)
    end
  end
end
