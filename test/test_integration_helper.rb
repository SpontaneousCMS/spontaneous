# encoding: UTF-8

# Helpers for integration tests
require "rubygems"
# require "bundler/setup"
require "minitest/unit"
require "minitest/autorun"
require 'tmpdir'
require 'pp'

# A test case that reproduces the actions of a user and hence need to run in order
# I.e. I don't suck thank you very much
class OrderedRunner < MiniTest::Unit
  def before_suites
  end

  def after_suites
  end

  def _run_suites(suites, type)
    begin
      before_suites
      super(suites, type)
    ensure
      after_suites
    end
  end

  def _run_suite(suite, type)
    begin
      suite.before_suite if suite.respond_to?(:before_suite)
      super(suite, type)
    ensure
      suite.after_suite if suite.respond_to?(:after_suite)
    end
  end
end

MiniTest::Unit.runner = OrderedRunner.new

class OrderedTestCase < MiniTest::Unit::TestCase
  i_suck_and_my_tests_are_order_dependent!
end
