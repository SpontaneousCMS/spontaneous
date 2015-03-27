# encoding: UTF-8

# Set up the Spontaneous environment
ENV["SPOT_ENV"] = "test"

require "rubygems"
require "bundler"
Bundler.setup(:default, :development)
gem 'minitest'

Bundler.require

# include these paths to enable the direct running of a test file
test_path = File.expand_path('..', __FILE__)
spot_path = File.expand_path('../../lib', __FILE__)
$:.unshift(test_path) if File.directory?(test_path) && !$:.include?(test_path)
$:.unshift(spot_path) if File.directory?(spot_path) && !$:.include?(spot_path)

require 'rack'
require 'timecop'
require 'logger'

Sequel.extension :migration

# http://sequel.jeremyevans.net/rdoc-plugins/index.html
# The scissors plugin adds class methods for update, delete, and destroy
Sequel::Model.plugin :scissors

ENV["SPOT_ADAPTER"] ||= "sqlite"

jruby = case RUBY_PLATFORM
when "java"
  true
else
  false
end

require 'mysql2'
require 'pg'
require 'sqlite3'

connection_string = \
case ENV["SPOT_ADAPTER"]
when "postgres"
  if jruby
    require 'jdbc/postgres'
    Jdbc::Postgres.load_driver
    "jdbc:postgresql:///spontaneous2_test"
  else
    "postgres:///spontaneous2_test"
  end
when "mysql"
  if jruby
    require 'jdbc/mysql'
    Jdbc::MySQL.load_driver
    "jdbc:mysql://localhost/spontaneous2_test?user=root"
  else
    "mysql2://root@localhost/spontaneous2_test"
  end
when "sqlite"
  if jruby
    require 'jdbc/sqlite3'
    Jdbc::SQLite3.load_driver
    "jdbc:sqlite::memory:"
  else
    "sqlite:/" # in-memory
  end
end

puts "SPOT_ADAPTER=#{ENV["SPOT_ADAPTER"]} => #{connection_string}"

DB = Sequel.connect(connection_string) unless defined?(DB)
# DB.logger = Logger.new($stdout)

Sequel::Migrator.apply(DB, 'db/migrations')

require File.expand_path(File.dirname(__FILE__) + '/../lib/spontaneous')

require 'minitest/unit'
require 'minitest/spec'
require 'minitest-colorize'
require 'mocha/setup'
require 'pp'
require 'tmpdir'
require 'json'

require 'support/rack'
require 'support/matchers'
require 'support/minitest'

MiniTest::Unit.runner = StartFinishRunner.new

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
  attr_accessor :template_root
  alias :silence_stdout :silence_logger

  def self.setup_site(root = nil, define_models = true)
    root ||= Dir.mktmpdir
    site = Spontaneous::Site.instantiate(root, :test, :back)
    site.schema_loader_class = Spontaneous::Schema::TransientMap
    site.logger.silent!
    site.database = DB
    site.background_mode = :immediate
    unless Object.const_defined?(:Content)
      content_class = Class.new(Spontaneous::Model!(:content, DB, site.schema))
      Object.const_set :Content, content_class
      if define_models
        Object.const_set :Page, Class.new(::Content::Page)
        Object.const_set :Piece, Class.new(::Content::Piece)
        Object.const_set :Box, Class.new(::Content::Box)
      end
    end
    site.model = ::Content
    # Use the fast version of the password hashing algorithm
    Spontaneous::Crypt.force_version(0)
    site
  end

  def self.teardown_site(clear_disk = true, clear_const = true)
    if clear_disk
      FileUtils.rm_r(Spontaneous.instance.root) rescue nil
    end
    return unless clear_const
    %w(Piece Page Box Content).each do |klass|
      Object.send :remove_const, klass if Object.const_defined?(klass)
    end
    Spontaneous.send :remove_const, :Content rescue nil
  end

  def self.stub_time(time)
    Sequel.datetime_class.stubs(:now).returns(time)
    Time.stubs(:now).returns(time)
  end
  def stub_time(time)
    self.class.stub_time(time)
  end

  def assert_content_equal(result, compare, *ignore_columns)
    serialised_columns = [:field_store]
    columns = Content.columns - serialised_columns - ignore_columns
    columns.each do |col|
      assert_equal(result[col], compare[col], "Column '#{col}' should be equal")
    end
    serialised_columns.each do |col|
      result.send(col).must_equal compare.send(col)
    end
  end

  def assert_content_unequal(result, compare, *ignore_columns)
    serialised_columns = [:field_store]
    columns = Content.columns - serialised_columns - ignore_columns
    columns.each do |col|
      return true unless result[col] == compare[col]
    end
    serialised_columns.each do |col|
      return true unless result.send(col) == compare.send(col)
    end
    flunk("#{result} & #{compare} are equal")
  end


  def self.log_sql(&block)
    logger = ::Content.mapper.logger
    ::Content.mapper.logger = ::Logger.new($stdout)
    yield
  ensure
    ::Content.mapper.logger = logger
  end

  def log_sql(&block)
    self.class.log_sql(&block)
  end

  def setup_site(root = nil, define_models = true)
    self.class.setup_site(root, define_models)
  end

  def teardown_site(clear_disk = true, clear_const = true)
    self.class.teardown_site(clear_disk, clear_const)
  end

  def assert_correct_template(content, expected_path, renderer, format = :html)
    assert_equal(expected_path, content.template(format, renderer))
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

  def assert_login_page(path = nil, method = "GET")
    assert last_response.status == 401, "#{method} #{path} should have status 401 but has #{last_response.status}"
    last_response.body.must_match %r{<form.+action="/@spontaneous/login"}
    last_response.body.must_match %r{<form.+method="post"}
    last_response.body.must_match %r{<input.+name="user\[login\]"}
    last_response.body.must_match %r{<input.+name="user\[password\]"}
  end

  def assert_contains_csrf_token(key)
    body = last_response.body
    match = /csrf_token: *('|")(.*)\1/.match(body)
    flunk "CSRF token not included in template" unless match
    token = match[2]
    assert key.csrf_token_valid?(token), "Invalid token #{token.inspect}"
  end
end

require 'minitest/autorun'
