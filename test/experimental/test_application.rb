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
        @page.in_progress.page.should == @page
        @page.completed.page.should == @page
        @page.archived.page.should == @page

        @page.in_progress.entries.first.page.should == @page
        @page.in_progress.entries.first.images.page.should == @page
      end
    end

    context "pages" do
      should "have references back to their parent" do
        @page2.parent.should == @page
      end

      should "have links to their children" do
        @page.children.should == [@page2]
      end

      should "have a correct ancestor list" do
        @page2.ancestors.should == [@page]
      end
    end
  end
end



