# encoding: UTF-8

# Set up the Spontaneous environment
ENV["SPOT_ENV"] = "test"

require "rubygems"
require "bundler"
gem 'minitest'
Bundler.setup(:default, :development)

Bundler.require

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
begin
  require 'leftright'
rescue LoadError
  # fails for ruby 1.9
end

require 'support/custom_matchers'
# require 'support/timing'


Spontaneous.database = DB

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
      Spontaneous.logger.silent!
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


module StartupShutdown
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def startup
      puts "+ Running #{self.name} startup"
    end

    def shutdown
      puts "- Running #{self.name} shutdown"
    end
  end # ClassMethods
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

  alias :silence_stdout :silence_logger

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

  def setup_site_fixture
    @app_dir = File.expand_path("../fixtures/application", __FILE__)
    File.exists?(@app_dir).should be_true
    Spontaneous.stubs(:application_dir).returns(@app_dir)
    @saved_schema_root = Spontaneous.schema_root
    @saved_template_root = Spontaneous.template_root
    Spontaneous.schema_root = nil
    Spontaneous.template_root = nil
    Spontaneous.root = File.expand_path("../fixtures/example_application", __FILE__)
    File.exists?(Spontaneous.root).should be_true
    Spontaneous.init(:mode => :back, :environment => :development)
    # Schema.load

    Object.const_get(:HomePage).must_be_instance_of(Class)

    # Sequel::Migrator.apply(Spontaneous.database, 'db/migrations')
    #########
    Spontaneous::Content.delete

    @carbon_quilt = ClientProject.new(:title => "The Carbon Quilt", :url => "http://carbonquilt.org/", :description => "In partnership with GovEd and CarbonSense magnetised was given the opportunity to transform their ground-breaking ideas for carbon visualisation into a working prototype. The result is both useful and compelling, turning abstract ideas of \"carbon footprints\" into intuitively understandable forms and volumes.\nThis is just an early prototype of what we hope will become one of the de-facto mechanisms for carbon visualisation online.")
    @barakapoint = ClientProject.new(:title => "Baraka Point", :url => "http://barakapoint.com/", :description => "Time has not stood still and the original [barakapoint.com](http://barakapoint.com/), produced in early 2003, is in need of a facelift. The new site will take full advantage of this brave new broadband-enabled world to deliver stunning images of this gorgeous luxury villa to a public desperately in need of some luxury.")

    @scf = ClientProject.new(:title => "Smart City Futures", :url => "http://www.smartcityfutures.co.uk/", :description => "Just-b were desperately in need of someone able to produce a CMS powered website in readiness for the Smart City Futures event on 23rd of July, 2009. Working to tight deadlines and an expanding brief magnetised, using [spontaneous](/products/spontaneous), was able to develop and launch a fully-editable, focussed and engaging public website in record time.")
    @ef = ClientProject.new(:title => "Edward Fields", :url => "http://www.edwardfields.com/", :description => "In collaboration with [spin](http://spin.co.uk/), we wove carpet makers Edward Fields a beautiful new site. This time the ever-flexible [spontaneous](/products/spontaneous) is acting as a bridge to the flash animation, highlighting the advantages of the site-independent nature of its intuitive editing interface.")
    @dm = ClientProject.new(:title => "The Design Museum", :url => "http://designmuseum.org", :description => "An iconic site for an iconic institution. [spontaneous](/products/spontaneous) was designed to deal with the kind of demands placed on a CMS by exciting design and here it excels.")

    @home = HomePage.new(:title => "Home", :introduction => "Welcome to magnetised. Read more in the [about page](/about).", :uid => "home", :welcome_title => "magnetised")

    @home.in_progress << @carbon_quilt
    @home.in_progress << @barakapoint
    @home.completed << @scf
    @home.completed << @ef
    @home.archived << @dm
    @home.save


    @about = InfoPage.new({ :slug => "about", :uid => "about", :title => "About" })

    @home.pages << @about

    @piece2_1 = Text.new(:text => "Text 1")
    @piece2_2 = Text.new(:text => "Text 2")
    @piece2_3 = Text.new(:text => "Text 3")
    @piece2_4 = Text.new(:text => "Text 4")
    @piece2_5 = Text.new(:text => "Text 5")
    @about.contents << @piece2_1
    @about.contents << @piece2_2
    @about.contents << @piece2_3
    @about.contents << @piece2_4
    @about.contents << @piece2_5
    @about.save
    # @home.save

    @projects = ProjectsPage.new(:slug => "projects", :title => "Projects", :introduction => "Welcome to projects page", :uid => "projects")
    @home.pages << @projects
    project = Project.new(:slug => "tiffl", :title => "TIFFL", :url => "http://tiffl.org", :description => "TIFFL gives you personalised access to the Transport for London Journey Planner.")
    @projects.projects << project
    @projects.projects << Project.new(:slug => "on-the-bbc", :title => "On the BBC", :url => "", :description => "On the BBC is an experiment that provides up-to-date twitter alerts for BBC radio and TV channels.")
    @projects.projects << Project.new(:slug => "human-remains", :title => "Human Remains", :url => "http://remains.magnetised.info/", :description => "A project exploring our relationship to our own detritus.")
    # [@carbon_quilt, @project2, @project3, @piece2_1, @piece2_2, @piece2_3, @piece2_4, @piece2_5].each { |p| p.save }

    @projects.save

    @products = ProjectsPage.new(:slug => "products", :title => "Products",  :introduction => "Magnetised's commercial offerings.", :uid => "products")
    @home.pages << @products

    @spon = Project.new(:slug => "spontaneous", :title => "Spontaneous CMS",  :url => "http://spontaneouscms.com", :description => "Spontaneous is magnetised's world-class Content Management System, designed around an elegant, intuitive and powerful editing interface.")
    @products.projects << @spon
    @products.save
    @home.save


    # @barakapoint.images << ProjectImage.new(:image => "/Users/garry/Dropbox/Profession/magnetised.info/content/i/work/ef/001.jpg")
    # @barakapoint.images << ProjectImage.new(:image => "/Users/garry/Dropbox/Profession/magnetised.info/content/i/work/ef/002.jpg")
    # @barakapoint.images << ProjectImage.new(:image => "/Users/garry/Dropbox/Profession/magnetised.info/content/i/work/ef/003.jpg")
    @barakapoint.save
    ############
    @home = Content[@home.id]
    @about = Content[@about.id]
    @projects = Content[@projects.id]
    @products = Content[@products.id]

    @home.root?.should be_true

  end

  def teardown_site_fixture
    # to keep other tests working
    Spontaneous.schema_root = @saved_schema_root
    Spontaneous.template_root = @saved_template_root
    # Schema.classes.each do |klass|
    #   Object.send(:remove_const, klass.name.to_sym) rescue nil
    # end
  end
end



require 'minitest/autorun'


