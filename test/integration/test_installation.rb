# encoding: UTF-8

require File.expand_path('../../test_integration_helper', __FILE__)

describe "Installation" do
  def system(command)
    puts "SYSTEM #{command.inspect}"
    Kernel.system command
  end

  before do
    @root = Dir.mktmpdir
    Dir.chdir(@root)
    puts "root.before"
  end

  describe "when starting with a base system" do
    before do
      puts "describe.before"
    end

    it "will allow the installation of the spontaneous gem" do
      assert_raises "Precondition failed, spontaneous gem is already installed", Gem::LoadError do
        Gem::Specification.find_by_name("spontaneous")
      end
      system "gem install spontaneous --prerelease --no-rdoc --no-ri"
      spec = Gem::Specification.find_by_name("spontaneous")
      asssert_instance_of Gem::Specification, spec, "spontaneous gem should have been installed"
    end
  end
end
