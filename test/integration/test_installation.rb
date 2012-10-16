# encoding: UTF-8

require File.expand_path('../../test_integration_helper', __FILE__)

class InstallationTest < MiniTest::Spec
  context "installation" do
    setup do
      @site = setup_site
      Dir.chdir(@site.root)
    end
  end
end
