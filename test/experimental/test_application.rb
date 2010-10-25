require 'test_helper'


class ApplicationTest < Test::Unit::TestCase
  context "content building" do
    setup do
      setup_site_fixture
    end

    teardown do
      teardown_site_fixture
    end

    context "site content" do
      should "contain references to their owning page" do
        @home.in_progress.page.should == @home
        @home.completed.page.should == @home
        @home.archived.page.should == @home

        @home.in_progress.entries.first.page.should == @home
        @home.in_progress.entries.first.images.page.should == @home
      end
    end

    context "pages" do
      should "have references back to their parent" do
        @about.parent.should == @home
      end

      should "have links to their children" do
        @home.children.should == [@about, @projects, @products]
      end

      should "have a correct ancestor list" do
        @about.ancestors.should == [@home]
      end
    end
  end
end



