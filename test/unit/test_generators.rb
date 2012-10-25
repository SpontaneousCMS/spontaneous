# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# borrowed from Padrino
class GeneratorsTest < MiniTest::Spec
  include Spontaneous

  def setup
    @tmp = "#{Dir.tmpdir}/spontaneous-tests/#{Time.now.to_i}"
    `mkdir -p #{@tmp}`
  end

  def teardown
    conn = Sequel.mysql2(:user => "root")
    %w(example_com example_com_test).each do |db|
      conn.run("DROP DATABASE `#{db}`") rescue nil
    end
    `rm -rf #{@tmp}`
  end


  def generate(name, *params)
    silence_logger {
      "Spontaneous::Generators::#{name.to_s.camelize}".constantize.start(params)
    }
  end

  def database_config(path)
    path = File.join(@tmp, path, "config/database.yml")
    YAML.load_file(path)
  end

  attr_reader :site_root

  context "Site generator" do
    teardown do
    end
    should "create a site using passed parameters" do
      # puts @tmp
      generate(:site, "example.com", "--root=#{@tmp}")
      # Have moved db creation into separate step (spot init) so this no longer applies
      # %w(example_com example_com_test).each do |db|
      #   db = Sequel.mysql2(:user => "root", :database => db)
      #   lambda { db.tables }.must_raise(Sequel::DatabaseConnectionError)
      # end
      site_root = File.join(@tmp, 'example_com')
      %w(Rakefile Gemfile).each do |f|
        assert_file_exists(site_root, f)
      end
      %w(development.rb production.rb).each do |f|
        assert_file_exists(site_root, 'config/environments', f)
      end
      %w(back.ru front.ru boot.rb database.yml deploy.rb environment.rb user_levels.yml indexes.rb).each do |f|
        assert_file_exists(site_root, 'config', f)
      end
      %w(favicon.ico robots.txt).each do |f|
        assert_file_exists(site_root, 'public', f)
      end
      %w(standard.html.cut).each do |f|
        assert_file_exists(site_root, 'templates/layouts', f)
      end
      assert_file_exists(site_root, 'schema')
      assert_file_exists(site_root, 'schema/page.rb')
      assert File.read(site_root / 'schema/page.rb') =~ /class Page < Spontaneous::Page/
      assert_file_exists(site_root, 'schema/piece.rb')
      assert_file_exists(site_root, 'schema/box.rb')
      assert File.read(site_root / 'schema/piece.rb') =~ /class Piece < Spontaneous::Piece/
      assert_file_exists(site_root, 'public/js')
      assert_file_exists(site_root, 'public/css')
      assert_file_exists(site_root, 'lib/tasks/example_com.rake')
      assert_file_exists(site_root, 'lib/site.rb')
      assert File.read(site_root / 'lib/site.rb') =~ /class Site < Spontaneous::Site/
      assert_file_exists(site_root, 'log')
      assert_file_exists(site_root, 'tmp')
      assert_file_exists(site_root, 'cache/media')
      assert_file_exists(site_root, 'cache/tmp')
      assert_file_exists(site_root, 'cache/revisions')
      assert_file_exists(site_root, '.gitignore')
      assert File.read(site_root / '.gitignore') =~ /cache\/\*/
      assert File.read(site_root / 'schema/piece.rb') =~ /class Piece < Spontaneous::Piece/
    end

    should "specify the current version of spontaneous as the dependency" do
      generate(:site, "example.com", "--root=#{@tmp}")
      site_root = File.join(@tmp, 'example_com')
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.should =~ /^gem 'spontaneous', +'~> *#{Spontaneous::VERSION}'$/
    end

    should "correctly configure the site for a 'mysql' database" do
      site_root = File.join(@tmp, 'example_com')
      generate(:site, "example.com", "--root=#{@tmp}", "--database=mysql", "--host=127.0.0.1")
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.should =~ /^gem 'mysql2'/
      config = database_config("example_com")
      [:development, :test, :production].each do |environment|
        config[environment][:adapter].should == "mysql2"
        config[environment][:database].should =~ /^example_com(_test)?/
        # db connections seem to work if you exclude the host
        config[environment][:host].should == "127.0.0.1"
      end
    end

    should "correctly configure the site for a 'postgresql' database" do
      site_root = File.join(@tmp, 'example_com')
      generate(:site, "example.com", "--root=#{@tmp}", "--database=postgresql", "--host=")
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.should =~ /^gem 'pg'/
      config = database_config("example_com")
      [:development, :test, :production].each do |environment|
        config[environment][:adapter].should == "postgres"
        config[environment][:database].should =~ /^example_com(_test)?/
        config[environment].key?(:host).should be_false
      end
    end

    should "correctly configure the site for a 'postgres' database" do
      site_root = File.join(@tmp, 'example_com')
      generate(:site, "example.com", "--root=#{@tmp}", "--database=postgres")
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.should =~ /^gem 'pg'/
      config = database_config("example_com")
      [:development, :test, :production].each do |environment|
        config[environment][:adapter].should == "postgres"
      end
    end

    should "include specified connection params in the generated database config" do
      site_root = File.join(@tmp, 'example_com')
      generate(:site, "example.com", "--root=#{@tmp}", "--database=postgres", "--user=spontaneous", "--password=s3cret")
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.should =~ /^gem 'pg'/
      config = database_config("example_com")
      [:development, :test].each do |environment|
        config[environment][:user].should == "spontaneous"
        config[environment][:password].should == "s3cret"
      end
    end
  end

  context "Page generator" do
    setup do
      generate(:site, "example.com", "--root=#{@tmp}")
      @site_root = File.join(@tmp, 'example_com')
    end

    should "create a page class and associated templates" do
      %w(large_page LargePage).each do |name|
        generate(:page, name, "--root=#{site_root}")
        assert_file_exists(site_root, 'schema/large_page.rb')
        # assert_file_exists(site_root, 'templates/large_page/page.html.cut')
        assert_file_exists(site_root, 'templates/large_page.html.cut')
        class_file = ::File.join(site_root,  'schema/large_page.rb')
        assert /class LargePage < Page/ === File.read(class_file)
        `rm -rf #{@tmp}`
      end
    end
  end
end
