# encoding: UTF-8

require File.expand_path('../../test_integration_helper', __FILE__)

class SpontaneousInstallationTest < OrderedTestCase

  def self.before_suite
    if ENV["GEM_SOURCE"] == "rubygems"
      @@gem = "spontaneous"
    else
      system "rm -rf pkg && rake gem:build"
      @@gem = File.expand_path(Dir["pkg/*.gem"].last)
    end
  end

  def self.after_suite
    system "gem uninstall -a -x -I spontaneous"
  end

  def system(command)
    puts "$ #{command}"
    Kernel.system command
  end

  def setup
    @root = Dir.mktmpdir
    Dir.chdir(@root)
  end

  def test_step_001__gem_installation
    assert_raises "Precondition failed, spontaneous gem is already installed", Gem::LoadError do
      Gem::Specification.find_by_name("spontaneous")
    end
    system "gem install #{@@gem} --no-rdoc --no-ri"
    Gem.refresh
    spec = Gem::Specification.find_by_name("spontaneous")
    assert_instance_of Gem::Specification, spec, "spontaneous gem should have been installed"
  end

  def test_step_002__invalid_site_creation
  end

  def test_step_003__valid_site_creation
  end

  def test_step_004__site_initialization
  end
end

