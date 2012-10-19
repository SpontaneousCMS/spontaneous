# encoding: UTF-8

require File.expand_path('../../test_integration_helper', __FILE__)

require 'open3'
require 'expect'
require 'yaml'
require 'etc'

ENV["DB"]      ||= "mysql"
ENV["DB_USER"] ||= "root"

puts "--- Testing against db #{ENV["DB"]} (#{ENV["DB_USER"]})"

$_pwd = Dir.pwd

# Test both the currently released gem and the development version
# This is mostly about dependencies
if ENV["GEM_SOURCE"] == "rubygems"
  $_gem = "spontaneous"
else
  system "rm -rf pkg && rake gem:build"
  $_gem = File.expand_path(Dir["pkg/*.gem"].last)
end

$_root = Dir.mktmpdir
Dir.chdir($_root)


class SpontaneousInstallationTest < OrderedTestCase

  def self.before_suite
  end

  def self.after_suite
    Kernel.system "gem uninstall -a -x -I spontaneous"
    Dir.chdir($_pwd)
    FileUtils.rm_r($_root)
  end

  def system(command, env = {})
    puts "$ #{command}" #if $DEBUG
    Open3.popen3(env, command) do |stdin, stdout, stderr, wait_thread|
      out = stdout.read.chomp
      err = stderr.read.chomp
      sts = wait_thread.value
      [sts, out, err]
    end
  end

  def existing_databases(database = ENV["DB"])
    case database
    when "postgres"
      status, out, _ = system "psql -t -l -U #{ENV["DB_USER"]}"
      databases = out.split("\n").map { |line| line.split("|").first.strip }
    when "mysql"
      status, out, _ = system "mysql -u #{ENV["DB_USER"]} --skip-column-names -e 'show databases'"
      databases = out.split("\n").map { |line| line.strip }
    end
  end

  def setup
    @account = {
      :login => Etc.getlogin,
      :password => "0123456789",
      :name => "A User",
      :email => "auser@example.com"
    }
  end

  def test_step_001__gem_installation
    assert_raises "Precondition failed, spontaneous gem is already installed", Gem::LoadError do
      Gem::Specification.find_by_name("spontaneous")
    end
    system "gem install #{$_gem} --no-rdoc --no-ri"
    Gem.refresh
    @spec = Gem::Specification.find_by_name("spontaneous")
    assert_instance_of Gem::Specification, @spec, "spontaneous gem should have been installed"
  end


  def test_step_002__spontaneous_version
    @spec = Gem::Specification.find_by_name("spontaneous")
    %w(version --version -v).each do |opt|
      status, version, _ = system "spot #{opt}"
      assert status.exitstatus == 0, "Expected status of 0 but got #{status.exitstatus}"
      assert_match /#{@spec.version.to_s}/, version, "Got an incorrect version #{version.inspect} for spontaneous"
    end
  end

  def test_step_003__valid_site_creation
    domain = "example.org"
    refute File.exist?("example_org"), "Precondition failed, site directory should not exist"
    status, output, err = system "spot generate --database=#{ENV["DB"]} --user=#{ENV["DB_USER"]} --host=#{ENV["DB_HOST"]} #{domain}"
    assert status.exitstatus == 0, "Expected status of 0 but got #{status.exitstatus}"
    assert File.exist?("example_org"), "Site directory should exist after generation step"
    Dir.chdir("example_org")
    assert File.exist?("Gemfile")
    assert File.exist?("config/schema.yml")
  end

  def test_step_004__bundler_should_install_dependencies
    status, output, err = system "bundle install --without development test", { "BUNDLE_GEMFILE" => File.expand_path("Gemfile") }
    assert status.exitstatus == 0, "Bundler failed to run #{err.inspect}"
  end

  def test_step_005__site_initialization_should_run
    cmd =  "spot init --user=#{ENV['DB_USER']} "
    cmd << "--account login:#{@account[:login]} email:#{@account[:email]} name:'#{@account[:name]}' password:#{@account[:password]}"
    status, out, err = system cmd
    puts out
    puts err
    unless status.exitstatus == 0
      fail "init task failed with error"
    end
  end

  def test_step_006__site_initialization_should_create_databases
    db_config = YAML.load_file("config/database.yml")
    assert existing_databases.include?(db_config[:development][:database]),
      "Database '#{db_config[:development][:database]}' should have been created"
  end

  def test_step_007__site_initialization_should_run_migrations
    %w(example_org example_org_test).each do |db|
      tables = case ENV["DB"]
               when "postgres"
                 status, out, _ = system "psql -t -U #{ENV["DB_USER"]} -d #{db} -c '\\dt'"
                 out.split("\n").map { |line| line.split("|")[1].strip }
               when "mysql"
                 status, out, _ = system "mysql -u #{ENV["DB_USER"]} --skip-column-names -e 'show tables' #{db}"
                 out.split("\n").map { |line| line.strip }
               end
      expected = %w(content spontaneous_users spontaneous_state)
      assert (expected & tables) == expected, "Migration has not created expected tables: #{tables}"
    end
  end

  def test_step_008__site_initialization_should_add_root_user
    # this now works because we install the gem above
    require 'spontaneous'
    Spontaneous.init mode: :console
    users = Spontaneous::Permissions::User.all
    assert users.length == 1, "Site initialization should have created a root user"
    user = users.first
    assert user.login == @account[:login], "Incorrect login #{user.login}"
    assert user.email == @account[:email], "Incorrect email #{user.email}"
    assert user.level.to_sym == :root, "Incorrect level #{user.level}"
    key = Spontaneous::Permissions::User.authenticate(@account[:login], @account[:password])
    assert_instance_of Spontaneous::Permissions::AccessKey, key, "User created with incorrect password"
  end

  def test_step_009__site_initialization_should_not_add_root_user_if_exists
    require 'spontaneous'
    cmd =  "spot init --user=#{ENV['DB_USER']}"
    users = Spontaneous::Permissions::User.count
    assert users == 1, "Precondition failed. There should only be 1 user"
    status, out, _ = system cmd
    users = Spontaneous::Permissions::User.count
    assert users == 1, "Re-running the 'init' command shouldn't add another user"
  end

  def test_step_010__site_initialization_should_append_auto_login_config
    config = File.read("config/environments/development.rb")
    assert_match /^\s*auto_login +('|")#{@account[:login]}\1/, config,
      "Config should include auto_login for '#{@account[:login]}'"
      # auto_login 'dev'
  end
end

