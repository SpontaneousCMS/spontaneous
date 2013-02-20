# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Structure" do

  before do
    @site = setup_site
    Content.delete
    Page.field :title
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

  after do
    [:HomePage, :Project, :ProjectPage, :Image].each { |klass| Object.send(:remove_const, klass) rescue nil }
    teardown_site
  end

  describe "site content" do
    it "contain references to their owning page" do
      @home.in_progress.page.must_equal @home

      @home.in_progress.contents.first.page.must_equal @home
      @home.in_progress.contents.first.images.page.must_equal @home
    end
    it "have the right depth" do
      @home.in_progress.depth.must_equal 0
      @home.in_progress.last.depth.must_equal 1
      @home.in_progress.last.images.depth.must_equal 1
      @home.depth.must_equal 0
      @project1.depth.must_equal 1
      @project1.reload.depth.must_equal 1
    end
  end

  describe "pages" do
    it "have references back to their parent" do
      @project1.parent.must_equal @home
    end

    it "have links to their children" do
      @home.children.must_equal [@project1]
    end

    it "have a correct ancestor list" do
      @project1.ancestors.must_equal [@home]
    end
  end
end
