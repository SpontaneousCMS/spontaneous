# encoding: UTF-8

require 'test_helper'

# borrowed from Padrino
class GeneratorsTest < Test::Unit::TestCase
  include Spontaneous

  def setup
    @tmp = "#{Dir.tmpdir}/spontaneous-tests/#{Time.now.to_i}"
    `mkdir -p #{@tmp}`
  end

  def teardown
    conn = Sequel.mysql2(:user => "root")
    %w(pot8o_org pot8o_org_test).each do |db|
      conn.run("DROP DATABASE `#{db}`") rescue nil
    end
    `rm -rf #{@tmp}`
  end


  def generate(name, *params)
    silence_logger {
      "Spontaneous::Generators::#{name.to_s.camelize}".constantize.start(params)
    }
  end

  attr_reader :site_root

  context "Site generator" do
    teardown do
    end
    should "create a site using passed parameters" do
      # puts @tmp
      generate(:site, "pot8o.org", "--root=#{@tmp}")
      %w(pot8o_org pot8o_org_test).each do |db|
        db = Sequel.mysql2(:user => "root", :database => db)
        lambda { db.tables }.should_not raise_error(Sequel::DatabaseConnectionError)
      end
      site_root = File.join(@tmp, 'pot8o_org')
      %w(Rakefile Gemfile).each do |f|
        assert_file_exists(site_root, f)
      end
      %w(development.rb production.rb).each do |f|
        assert_file_exists(site_root, 'config/environments', f)
      end
      %w(back.ru front.ru boot.rb database.yml deploy.rb environment.rb user_levels.yml).each do |f|
        assert_file_exists(site_root, 'config', f)
      end
      %w(favicon.ico robots.txt).each do |f|
        assert_file_exists(site_root, 'public', f)
      end
      %w(page.html.cut).each do |f|
        assert_file_exists(site_root, 'templates', f)
      end
      assert_file_exists(site_root, 'schema')
      assert_file_exists(site_root, 'public/js')
      assert_file_exists(site_root, 'public/css')
      assert_file_exists(site_root, 'lib/tasks/pot8o_org.rake')
      assert_file_exists(site_root, 'log')
      assert_file_exists(site_root, 'tmp')
      assert_file_exists(site_root, '.gitignore')
    end
    should "accept domain names starting with numbers"
    should "accept domain names containing dashes"
  end

  context "Page generator" do
    setup do
      generate(:site, "pot8o.org", "--root=#{@tmp}")
      @site_root = File.join(@tmp, 'pot8o_org')
    end
    should "create a page class and associated templates" do
      %w(large_page LargePage).each do |name|
        generate(:page, name, "--root=#{site_root}")
        assert_file_exists(site_root, 'schema/large_page.rb')
        assert_file_exists(site_root, 'templates/large_page/page.html.cut')
        assert_file_exists(site_root, 'templates/large_page/inline.html.cut')
        class_file = ::File.join(site_root,  'schema/large_page.rb')
        assert /class LargePage < Spontaneous::Page/ === File.read(class_file)
        `rm -rf #{@tmp}`
      end
    end
  end
end
