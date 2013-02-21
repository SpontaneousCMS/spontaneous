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

# for future integration with travis
ENV["SPOT_ADAPTER"] ||= "postgres"

jruby = case RUBY_PLATFORM
           when "java"
             true
           else
             false
           end


connection_string = \
  case ENV["SPOT_ADAPTER"]
  when "postgres"
    if jruby
      require 'jdbc/postgres'
      Jdbc::Postgres.load_driver
      "jdbc:postgresql:///spontaneous2_test"
    else
      require 'pg'
      "postgres:///spontaneous2_test"
    end
  when "mysql"
    if jruby
      require 'jdbc/mysql'
      Jdbc::MySQL.load_driver
      "jdbc:mysql://localhost/spontaneous2_test?user=root"
    else
      require 'mysql2'
      "mysql2://root@localhost/spontaneous2_test"
    end
  end

puts "DB Connection: #{connection_string}"
DB = Sequel.connect(connection_string) unless defined?(DB)
# DB.logger = Logger.new($stdout)

Sequel::Migrator.apply(DB, 'db/migrations')

require File.expand_path(File.dirname(__FILE__) + '/../lib/spontaneous')

require 'minitest/unit'
require 'minitest/spec'
require 'minitest/reporters'
require 'mocha/setup'
require 'pp'
require 'tmpdir'
require 'json'

require 'support/rack'
require 'support/matchers'

    # DB.loggers << ::Logger.new($stdout)

module TransactionalTest
  def run(runner)
    result = nil
    DB.transaction(:rollback => :always) { result = super }
    result
  end

  def run_test(name)
    super
  end

end

module MiniTest::StartFinish
  module Unit
    def _run_suites(suites, type)
      begin
        DB.synchronize do
          super(suites, type)
        end
      ensure
        if (suite = suites.last.master_suite)
          suite._run_finish_hook
        end
      end
    end

    def _run_suite(suite, type)
      begin
        if @_previous_suite && @_previous_suite.master_suite != suite.master_suite
          @_previous_suite.master_suite._run_finish_hook if @_previous_suite.master_suite
        end
        suite._run_start_hook
        super(suite, type)
      ensure
        @_previous_suite = suite unless suite == MiniTest::Spec
      end
    end
  end

end

class MiniTest::Spec
  include TransactionalTest
  class << self
    def parent_suite
      a = ancestors.take_while { |a| a != MiniTest::Spec }.select { |a| Class === a }
      a.last
    end

    def master_suite
      ancestors.detect { |a| a.respond_to?(:has_finish_hook?) && a.has_finish_hook? }
    end

    def has_finish_hook?
      !@finish_hook.nil?
    end

    def start(&block)
      @start_hook = block
    end

    def finish(&block)
      @finish_hook = block
    end

    def _hooks_run
      @_hooks_run ||= []
    end
    def _run_start_hook
      _run_start_finish_hook(@start_hook, :start)
    end

    def _run_finish_hook
      if _hooks_run.include?(:start)
        _run_start_finish_hook(@finish_hook, :finish)
      end
    end

    def _run_start_finish_hook(hook, label)
      _hooks_run << label
      hook.call if hook
    end
  end
end

class MiniTestWithHooks < MiniTest::Unit
  include MiniTest::StartFinish::Unit
  def exclude?(suite)
    return true if suite.nil?
    [MiniTest::Spec].include?(suite) || !suite.ancestors.include?(MiniTest::Spec)
  end

  def _run_suites(suites, type)
    names = suites.map(&:parent_suite).reject { |s| exclude?(s) }.uniq.map(&:to_s)
    @max_name_length = names.map(&:length).max
    super(suites, type)
  end

  def _run_suite(suite, type)
    unless exclude?(suite)
      if (name = suite.parent_suite.name) != @_previous_suite_name
        print "\n#{name.ljust(@max_name_length, " ")}  "
        @_previous_suite_name = name
      end
    end
    super(suite, type)
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

class Minitest::ReporterRunner
  include MiniTest::StartFinish::Unit
end

# MiniTest::Reporters.use! MiniTest::Reporters::DefaultReporter.new

class MiniTest::Spec

  attr_accessor :template_root
  alias :silence_stdout :silence_logger

  def self.setup_site(root = nil, define_models = true)
    root ||= Dir.mktmpdir
    instance = Spontaneous::Site.instantiate(root, :test, :back)
    instance.schema_loader_class = Spontaneous::Schema::TransientMap
    instance.logger.silent!
    instance.database = DB
    Spontaneous::Site.background_mode = :immediate
    unless Object.const_defined?(:Content)
      content_class = Class.new(Spontaneous::Model(:content, DB, instance.schema))
      Object.const_set :Content, content_class
      if define_models
        Object.const_set :Page, Class.new(::Content::Page)
        Object.const_set :Piece, Class.new(::Content::Piece)
        Object.const_set :Box, Class.new(::Content::Box)
      end
    end
    Object.const_set :Site,  Spontaneous.site!(::Content)
    # Use the fast version of the password hashing algorithm
    Spontaneous::Crypt.force_version(0)
    instance
  end

  def self.teardown_site(clear_disk = true, clear_const = true)
    if clear_disk
      FileUtils.rm_r(Spontaneous.instance.root) rescue nil
    end
    return unless clear_const
    %w(Piece Page Box Content Site).each do |klass|
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
    serialised_columns = [:field_store, :entry_store]
    columns = Content.columns - serialised_columns - ignore_columns
    columns.each do |col|
      assert_equal(result[col], compare[col], "Column '#{col}' should be equal")
    end
    serialised_columns.each do |col|
      result.send(col).must_equal compare.send(col)
    end
  end

  def assert_content_unequal(result, compare, *ignore_columns)
    serialised_columns = [:field_store, :entry_store]
    columns = Content.columns - serialised_columns - ignore_columns
    columns.each do |col|
      return true unless result[col] == compare[col]
    end
    serialised_columns.each do |col|
      return true unless result.send(col) == compare.send(col)
    end
    flunk("#{result} & #{compare} are equal")
  end


  def log_sql(&block)
    logger = ::Content.mapper.logger
    ::Content.mapper.logger = ::Logger.new($stdout)
    yield
  ensure
    ::Content.mapper.logger = logger
  end

  def setup_site(root = nil, define_models = true)
    self.class.setup_site(root, define_models)
  end

  def teardown_site(clear_disk = true, clear_const = true)
    self.class.teardown_site(clear_disk, clear_const)
  end

  def assert_correct_template(content, expected_path, format = :html)
    assert_equal(expected_path, content.template(format))
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


