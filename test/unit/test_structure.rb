# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class StructureTest < MiniTest::Spec
  context "content building" do
    setup do
      Content.delete
      Spot::Schema.reset!
      class Page < Spot::Page
        field :title
      end
      class Piece < Spot::Piece; end
      class ProjectPage < Page; end
      class Image < Piece; end
      class Project < Piece
        field :title
        box :images do
          allow Image
        end
      end
      class HomePage < Page
        box :projects do
          allow ProjectPage
        end
        box :in_progress do
          allow Project
        end
      end
      @home = HomePage.new(:title => "Home")
      @project1 = ProjectPage.new(:title => "Project 1")
      @project2 = Project.new(:title => "Project 2")
      @project3 = Project.new(:title => "Project 3")
      @image1 = Image.new

      @project2.images << @image1
      @home.projects << @project1
      @home.in_progress << @project2
      @home.in_progress << @project3

      @home.save
      @home = Content[@home.id]
      @project1 = Content[@project1.id]
    end

    teardown do
      [:Page, :HomePage, :Project, :ProjectPage, :Image].each { |klass| StructureTest.send(:remove_const, klass) rescue nil }
    end

    context "site content" do
      should "contain references to their owning page" do
        @home.in_progress.page.should == @home

        @home.in_progress.pieces.first.page.should == @home
        @home.in_progress.pieces.first.images.page.should == @home
      end
      should "have the right depth" do
        @home.in_progress.depth.should == 0
        @home.in_progress.last.depth.should == 1
        @home.in_progress.last.images.depth.should == 1
        @home.depth.should == 0
        @project1.depth.should == 1
        @project1.reload.depth.should == 1
      end
    end

    context "pages" do
      should "have references back to their parent" do
        @project1.parent.should == @home
      end

      should "have links to their children" do
        @home.children.should == [@project1]
      end

      should "have a correct ancestor list" do
        @project1.ancestors.should == [@home]
      end
    end
  end
end



