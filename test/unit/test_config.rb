# encoding: UTF-8

# require 'test_helper'
require "rubygems"
require "bundler"
Bundler.setup(:default, :development)

require 'logger'

begin
  require 'leftright'
rescue LoadError
  # fails for ruby 1.9
end

require 'test/unit'
require 'rack/test'
require 'matchy'
require 'shoulda'
require 'timecop'
require 'mocha'
require 'pp'

require 'support/custom_matchers'
require 'support/timing'

class ConfigTest < Test::Unit::TestCase
  include CustomMatchers
  context "Independent configuration loading" do
    setup do
      @pwd = Dir.pwd
      Dir.chdir(File.expand_path("../../fixtures/example_application", __FILE__))
      @lib_dir = File.expand_path(File.join(File.dirname(__FILE__), '../../../../../lib'))
      defined?(Spontaneous).should be_nil
      load @lib_dir + '/spontaneous/config.rb'
      Config = ::Spontaneous::Config
    end

    teardown do
      Object.send(:remove_const, :Spontaneous) rescue nil
      self.class.send(:remove_const, :Config)
      defined?(Spontaneous).should be_nil
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

    should "accept blocks/procs/lambdas as values"

    teardown do
      Dir.chdir(@pwd)
    end
  end
end
