# encoding: UTF-8

require "rubygems"
require "bundler"
Bundler.setup(:default, :development)

Bundler.require

require 'rack'
require 'logger'

begin
  require 'leftright'
rescue LoadError
  # fails for ruby 1.9
end

Sequel.extension :migration

DB = Sequel.connect('mysql2://root@localhost/spontaneous2_test') unless defined?(DB)
# DB = Sequel.connect('postgres://postgres@localhost/spontaneous2_test') unless defined?(DB)
# DB.logger = Logger.new($stdout)
Sequel::Migrator.apply(DB, 'db/migrations')

require File.expand_path(File.dirname(__FILE__) + '/../lib/spontaneous')
require File.expand_path(File.dirname(__FILE__) + '/../lib/cutaneous')

require 'test/unit'
require 'rack/test'
require 'matchy'
require 'shoulda'
require 'timecop'
require 'mocha'
require 'pp'

require 'support/custom_matchers'
require 'support/timing'


class Test::Unit::TestCase
  include Spontaneous
  include CustomMatchers

  def setup_site_fixture
    @app_dir = File.expand_path("../fixtures/application", __FILE__)
    File.exists?(@app_dir).should be_true
    Spontaneous.stubs(:application_dir).returns(@app_dir)
    @saved_schema_root = Spontaneous.schema_root
    Spontaneous.schema_root = nil
    Spontaneous.root = File.expand_path("../fixtures/example_application", __FILE__)
    File.exists?(Spontaneous.root).should be_true
    Spontaneous.init(:mode => :back, :environment => :development)
    # Schema.load

    Object.const_get(:HomePage).should be_instance_of(Class)

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


    @about = InfoPage.new({
      :slug => "about",
      :uid => "about",
      :title => "About"
    })

    @home.pages << @about

    @facet2_1 = Text.new(:text => "Text 1")
    @facet2_2 = Text.new(:text => "Text 2")
    @facet2_3 = Text.new(:text => "Text 3")
    @facet2_4 = Text.new(:text => "Text 4")
    @facet2_5 = Text.new(:text => "Text 5")
    @about.text << @facet2_1
    @about.text << @facet2_2
    @about.text << @facet2_3
    @about.text << @facet2_4
    @about.text << @facet2_5
    @about.save
    @home.save

    @projects = ProjectsPage.new(:slug => "projects", :title => "Projects", :introduction => "Welcome to projects page", :uid => "projects")
    @home.pages << @projects
    @projects.projects << Project.new(:slug => "tiffl", :title => "TIFFL", :url => "http://tiffl.org", :description => "TIFFL gives you personalised access to the Transport for London Journey Planner.")
    @projects.projects << Project.new(:slug => "on-the-bbc", :title => "On the BBC", :url => "", :description => "On the BBC is an experiment that provides up-to-date twitter alerts for BBC radio and TV channels.")
    @projects.projects << Project.new(:slug => "human-remains", :title => "Human Remains", :url => "http://remains.magnetised.info/", :description => "A project exploring our relationship to our own detritus.")
    # [@carbon_quilt, @project2, @project3, @facet2_1, @facet2_2, @facet2_3, @facet2_4, @facet2_5].each { |p| p.save }

    @projects.save

    @products = ProjectsPage.new(:slug => "products", :title => "Products",  :introduction => "Magnetised's commercial offerings.", :uid => "products")
    @home.pages << @products

    @spon = Project.new(:slug => "spontaneous", :title => "Spontaneous CMS",  :url => "http://spontaneouscms.com", :description => "Spontaneous is magnetised's world-class Content Management System, designed around an elegant, intuitive and powerful editing interface.")
    @products.projects << @spon
    @products.save
    @home.save


    @barakapoint.images << ProjectImage.new(:image => "/Users/garry/Dropbox/Profession/magnetised.info/content/i/work/ef/001.jpg")
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
    # Schema.classes.each do |klass|
    #   Object.send(:remove_const, klass.name.to_sym) rescue nil
    # end
  end
end





