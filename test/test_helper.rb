# encoding: UTF-8

# Set up the Spontaneous environment
ENV["SPOT_ENV"] = "test"

require "rubygems"
require "bundler"
gem 'minitest'
Bundler.setup(:default, :development)

Bundler.require

# include these paths to enable the direct running of a test file
test_path = File.expand_path('..', __FILE__)
spot_path = File.expand_path('../../lib', __FILE__)
$:.unshift(test_path) if File.directory?(test_path) && !$:.include?(test_path)
$:.unshift(spot_path) if File.directory?(spot_path) && !$:.include?(spot_path)

require 'rack'
require 'logger'


Sequel.extension :migration

DB = Sequel.connect('mysql2://root@localhost/spontaneous2_test') unless defined?(DB)
# DB = Sequel.connect('postgres://postgres@localhost/spontaneous2_test') unless defined?(DB)
# DB.logger = Logger.new($stdout)
Sequel::Migrator.apply(DB, 'db/migrations')

require File.expand_path(File.dirname(__FILE__) + '/../lib/spontaneous')
require File.expand_path(File.dirname(__FILE__) + '/../lib/cutaneous')

# require 'test/unit'
require 'minitest/spec'
require 'rack/test'
require 'matchy'
require 'shoulda'
require 'timecop'
require 'mocha'
require 'pp'
require 'tmpdir'

begin
  require 'leftright'
rescue LoadError
  # fails for ruby 1.9
end

require 'support/custom_matchers'
# require 'support/timing'


# Spontaneous.database = DB


class MiniTestWithHooks < MiniTest::Unit
  def before_suites
  end

  def after_suites
  end

  def exclude?(suite)
    [MiniTest::Spec, Test::Unit::TestCase].include?(suite)
  end

  def _run_suites(suites, type)
    names = suites.reject { |s| exclude?(s) }.map { |s| s.to_s.gsub(/Test$/, '') }
    @max_name_length = names.inject(-1) { |max, name| [name.length, max].max }
    begin
      before_suites
      super(suites, type)
    ensure
      after_suites
    end
  end

  def _run_suite(suite, type)
    begin
      unless exclude?(suite)
        print "\n#{suite.to_s.gsub(/Test$/, '').ljust(@max_name_length, " ")}  "
      end
      suite.startup if suite.respond_to?(:startup)
      super(suite, type)
    ensure
      suite.shutdown if suite.respond_to?(:shutdown)
    end
  end
end



MiniTest::Unit.runner = MiniTestWithHooks.new

def silence_logger(&block)
  begin
    $stdout = log_buffer = StringIO.new
    $stderr.reopen("/dev/null", 'w')
    block.call
  ensure
    $stdout = STDOUT
    $stderr = STDERR
    log_buffer.string
  end
end

class MiniTest::Spec
  include Spontaneous
  include CustomMatchers

  attr_accessor :template_root
  alias :silence_stdout :silence_logger

  def template_root=(template_root)
    @template_root = template_root
    Spontaneous.stubs(:template_paths).returns([@template_root])
  end

  def assert_correct_template(content, expected_path, format = :html)
    assert_equal(template_root / expected_path, content.template(format))
  end

  def assert_file_exists(*path)
    path = File.join(*path)
    assert File.exist?(path), "File at path '#{path}' does not exist!"
  end
  alias :assert_dir_exists :assert_file_exists

  def assert_hashes_equal(expected_hash, result_hash, path = [], level = 0)
    assert result_hash.is_a?(Hash), "'#{path[0..level].join(' > ')}' Expected a hash #{expected_hash.inspect} !== #{result_hash.inspect}"
    assert_equal expected_hash.keys.length, result_hash.keys.length, "'#{path[0..level].join(' > ')}' Expected #{expected_hash.keys.length} keys #{expected_hash.keys.inspect} !== #{result_hash.keys.inspect} >> #{(expected_hash.keys - result_hash.keys).inspect}"
    expected_hash.keys.each do |key|
      path[level] = key
      expected = expected_hash[key]
      result = result_hash[key]
      case expected
      when Hash
        assert_hashes_equal(expected, result, path, level+1)
      when Array
        assert_arrays_equal(expected, result, path, level+1)
      else
        assert_equal expected, result, "Key '#{path[0..level].join(' > ')}' should be identical"
      end
    end
  end

  def assert_arrays_equal(expected_array, result_array, path = [], level = 0)
    assert_equal expected_array.length, result_array.length
    expected_array.each_with_index do |expected, index|
      path[level] = index
      result = result_array[index]
      case expected
      when Hash
        assert_hashes_equal(expected, result, path, level+1)
      when Array
        assert_arrays_equal(expected, result, path, level+1)
      else
        assert_equal expected, result, "Key '#{path[0..level].join(' -> ')}' should be identical"
      end
    end
  end


end



require 'minitest/autorun'

