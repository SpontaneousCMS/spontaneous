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
# DB.logger = Logger.new($stdout)
Sequel::Migrator.apply(DB, 'db/migrations')

require File.expand_path(File.dirname(__FILE__) + '/../lib/spontaneous')

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
    # Sequel::Migrator.apply(Spontaneous.database, 'db/migrations')
    Spontaneous::Content.delete
    #########

    @project1 = Project.new(:title => "Spontaneous CMS 1", :url => "http://spontaneouscms.com", :description => "Description 1")
    @project2 = Project.new(:title => "Spontaneous CMS 2", :url => "http://spontaneouscms.com", :description => "Description 2")
    @project3 = Project.new(:title => "Spontaneous CMS 3", :url => "http://spontaneouscms.com", :description => "Description 3")

    @page = HomePage.new(:title => "magnetised", :introduction => "Welcome to magnetised...", :uid => "home", :welcome_title => "magnetised")
    @page.in_progress << @project1
    @page.completed << @project2
    @page.archived << @project3
    @page.save

    @page2 = InfoPage.new({
      :slug => "about",
      :uid => "about"
    })

    @page.pages << @page2

    @facet2_1 = Text.new(:text => "Text 1")
    @facet2_2 = Text.new(:text => "Text 2")
    @facet2_3 = Text.new(:text => "Text 3")
    @facet2_4 = Text.new(:text => "Text 4")
    @facet2_5 = Text.new(:text => "Text 5")
    @page2.text << @facet2_1
    @page2.text << @facet2_2
    @page2.text << @facet2_3
    @page2.text << @facet2_4
    @page2.text << @facet2_5
    @page2.text.save
    @page2.save
    @page.save
    [@project1, @project2, @project3, @facet2_1, @facet2_2, @facet2_3, @facet2_4, @facet2_5].each { |p| p.save }

    ############
    @page = Content[@page.id]
    @page2 = Content[@page2.id]

    @page.root?.should be_true
    Object.const_get(:HomePage).should be_instance_of(Class)

  end

  def teardown_site_fixture
    # to keep other tests working
    Spontaneous.schema_root = @saved_schema_root
  end
end





