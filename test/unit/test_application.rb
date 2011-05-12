# encoding: UTF-8

require 'test_helper'


class ApplicationTest < MiniTest::Spec
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

        @home.in_progress.pieces.first.page.should == @home
        @home.in_progress.pieces.first.images.page.should == @home
      end
      should "have the right depth" do
        @home.in_progress.depth.should == 0
        @home.in_progress.last.depth.should == 1
        @home.in_progress.last.images.depth.should == 1
        @home.depth.should == 0
        @about.depth.should == 1
        @projects.reload.depth.should == 1
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



