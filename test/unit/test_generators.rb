# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# borrowed from Padrino
describe "Generators" do
  include Spontaneous

  before do
    @tmp = "#{Dir.tmpdir}/spontaneous-tests/#{Time.now.to_i}"
    `mkdir -p #{@tmp}`
  end

  after do
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

  describe "Site generator" do
    after do
    end
    it "create a site using passed parameters" do
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
      %w(back.ru front.ru boot.rb database.yml deploy.rb environment.rb user_levels.yml).each do |f|
        assert_file_exists(site_root, 'config', f)
      end
      %w(favicon.ico robots.txt).each do |f|
        assert_file_exists(site_root, 'public', f)
      end
      %w(standard.html.cut).each do |f|
        assert_file_exists(site_root, 'templates/layouts', f)
      end
      assert_file_exists(site_root, 'config/initializers/indexes.rb')
      assert_file_exists(site_root, 'schema')
      assert_file_exists(site_root, 'schema/page.rb')
      assert File.read(site_root / 'schema/page.rb') =~ /class Page < Content::Page/
      assert_file_exists(site_root, 'schema/piece.rb')
      assert_file_exists(site_root, 'schema/box.rb')
      assert File.read(site_root / 'schema/piece.rb') =~ /class Piece < Content::Piece/
      assert_file_exists(site_root, 'assets')
      assert_file_exists(site_root, 'assets/README.md')
      assert_file_exists(site_root, 'assets/css/site.scss')
      assert_file_exists(site_root, 'assets/js/site.js')
      assert_file_exists(site_root, 'public/favicon.ico')
      assert_file_exists(site_root, 'public/robots.txt')
      content_rb =  File.read(site_root / 'lib/content.rb')
      assert content_rb =~ /class Content < Spontaneous::Model\(:content\)/
      assert content_rb =~ /^Site = Spontaneous\.site\(Content\)/
      assert_file_exists(site_root, 'lib/tasks/site.rake')
      assert_file_exists(site_root, 'log')
      assert_file_exists(site_root, 'tmp')
      assert_file_exists(site_root, 'cache/media')
      assert_file_exists(site_root, 'cache/tmp')
      assert_file_exists(site_root, 'cache/revisions')
      assert_file_exists(site_root, '.gitignore')
      assert File.read(site_root / '.gitignore') =~ /cache\/\*/
    end

    it "specify the current version of spontaneous as the dependency" do
      generate(:site, "example.com", "--root=#{@tmp}")
      site_root = File.join(@tmp, 'example_com')
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.must_match /^gem 'spontaneous', +'~> *#{Spontaneous::VERSION}'$/
    end

    it "correctly configure the site for a 'mysql' database" do
      site_root = File.join(@tmp, 'example_com')
      generate(:site, "example.com", "--root=#{@tmp}", "--database=mysql", "--host=127.0.0.1")
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.must_match /^gem 'mysql2'/
      config = database_config("example_com")
      [:development, :test, :production].each do |environment|
        config[environment][:adapter].must_equal "mysql2"
        config[environment][:database].must_match /^example_com(_test)?/
        case environment
        when :production
          config[environment][:user].must_equal "example_com"
        else
          config[environment][:user].must_equal "root"
        end
        # db connections seem to work if you exclude the host
        config[environment][:host].must_equal "127.0.0.1"
      end
    end

    describe "configured for a postgres database" do
      before do
        @site_root = File.join(@tmp, 'example_com')
      end

      it "define the correct adapter" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=postgres")
        config = database_config("example_com")
        [:development, :test, :production].each do |environment|
          config[environment][:adapter].must_equal "postgres"
        end
      end

      it "configure the correct gem" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=postgresql")
        gemfile = File.read(File.join(@site_root, "Gemfile"))
        gemfile.must_match /^gem 'sequel_pg'.+require: 'sequel'/
      end

      it "setup the right db parameters" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=postgresql")
        config = database_config("example_com")
        [:development, :test].each do |environment|
          config[environment][:adapter].must_equal "postgres"
          config[environment][:user].must_equal ENV["USER"]
          config[environment][:database].must_match /^example_com(_test)?/
          refute config[environment].key?(:host)
        end
      end

      it "honor the user parameter" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=postgresql", "--user=fred")
        config = database_config("example_com")
        [:development, :test].each do |environment|
          config[environment][:user].must_equal "fred"
        end
      end
    end

    describe "configured for a mysql database" do
      before do
        @site_root = File.join(@tmp, 'example_com')
      end

      it "define the correct adapter" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=mysql")
        config = database_config("example_com")
        [:development, :test, :production].each do |environment|
          config[environment][:adapter].must_equal "mysql2"
        end
      end

      it "configure the correct gem" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=mysql")
        gemfile = File.read(File.join(@site_root, "Gemfile"))
        gemfile.must_match /^gem 'mysql2'/
      end

      it "setup the right db parameters" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=mysql")
        config = database_config("example_com")
        [:development, :test].each do |environment|
          config[environment][:user].must_equal "root"
          config[environment][:database].must_match /^example_com(_test)?/
          refute config[environment].key?(:host)
        end
      end

      it "honor the user parameter" do
        generate(:site, "example.com", "--root=#{@tmp}", "--database=mysql", "--user=fred")
        config = database_config("example_com")
        [:development, :test].each do |environment|
          config[environment][:user].must_equal "fred"
        end
      end
    end

    describe "configured for a sqlite database" do
      let(:args) { ["example.com", "--root=#{@tmp}", "--database=sqlite"] }
      before do
        @site_root = File.join(@tmp, 'example_com')
        generate(:site, *args)
      end


      it "define the correct adapter" do
        config = database_config("example_com")
        [:development, :test, :production].each do |environment|
          config[environment][:adapter].must_equal "sqlite"
        end
      end

      it "configure the correct gem" do
        gemfile = File.read(File.join(@site_root, "Gemfile"))
        gemfile.must_match /^gem 'sqlite3'/
      end

      it "setup the right db parameters" do
        config = database_config("example_com")
        [:development, :test].each do |environment|
          config[environment][:database].must_match "db/#{environment}.sqlite3"
          refute config[environment].key?(:user)
          refute config[environment].key?(:host)
        end
      end
    end


    it "include specified connection params in the generated database config" do
      site_root = File.join(@tmp, 'example_com')
      generate(:site, "example.com", "--root=#{@tmp}", "--database=postgres", "--user=spontaneous", "--password=s3cret")
      gemfile = File.read(File.join(site_root, "Gemfile"))
      gemfile.must_match /^gem 'sequel_pg'.+require: 'sequel'/
      config = database_config("example_com")
      [:development, :test].each do |environment|
        config[environment][:user].must_equal "spontaneous"
        config[environment][:password].must_equal "s3cret"
      end
    end
  end

  describe "Page generator" do
    before do
      generate(:site, "example.com", "--root=#{@tmp}")
      @site_root = File.join(@tmp, 'example_com')
    end

    it "create a page class and associated templates" do
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
