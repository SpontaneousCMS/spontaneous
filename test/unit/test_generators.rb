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
      conn.run("DROP DATABASE `#{db}`")
    end
    # `rm -rf #{@tmp}`
  end


  def generate(name, *params)
    "Spontaneous::Generators::#{name.to_s.camelize}".constantize.start(params)
  end

  context "Site generator" do
    should "create a site using passed parameters" do
      puts @tmp
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
      %w(back.ru front.ru boot.rb database.yml deploy.rb environment.rb).each do |f|
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
    end
  end
end
