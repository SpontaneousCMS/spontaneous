# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Context" do
  describe "navigation helper" do
    before do
      @site = setup_site
      Page.box :area1
      Page.box :area2
      class ::OtherPage < Page
        box :area3
        box :area4
      end

      @root = Page.create
      @root.is_root?.must_equal true
      @area1_page1 = Page.create(slug: 'area1_page1')
      @area1_page2 = OtherPage.create(slug: 'area1_page2')
      @root.area1 << @area1_page1
      @root.area1 << @area1_page2
      @area2_page1 = Page.create(slug: 'area2_page1')
      @area2_page2 = OtherPage.create(slug: 'area2_page2')
      @root.area2 << @area2_page1
      @root.area2 << @area2_page2
      @context_class = Class.new do
        include Spontaneous::Output::Context::Navigation
        def initialize(target)
          @target = target
        end
        def __target
          @target
        end
      end
      [@root, @area1_page1, @area1_page2, @area2_page1, @area2_page2].each { |p| p.save.reload }
    end

    after do
      Content.delete
      teardown_site @site
      Object.send :remove_const, :OtherPage rescue nil
    end

    it "correctly flags active pages" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)

      result = @context.navigation.map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true], ["/area2-page1", false], ["/area2-page2", false]]
    end

    it "yields the results to a block if given" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = []
      @context.navigation { |p, a| result << [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true], ["/area2-page1", false], ["/area2-page2", false]]
    end

    it "doesn't show an active state for root" do
      @context = @context_class.new(@root)
      result = @context.navigation.map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", false], ["/area2-page1", false], ["/area2-page2", false]]
    end

    it "shows the section pages as active" do
      @context = @context_class.new(@area1_page2)
      result = @context.navigation.map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true], ["/area2-page1", false], ["/area2-page2", false]]
    end

    it "allows for limiting the navigation to a particular box with :only" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(only: :area1).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true]]
    end

    it "allows for limiting the navigation to a particular box with [ :only ]" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(only: [:area1]).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true]]
    end

    it "allows for limiting the navigation to a particular box with :box" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(box: :area1).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true]]
    end

    it "allows for limiting the navigation to a particular box with :boxes" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(boxes: [:area1]).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true]]
    end

    it "allows for excluding a particular box" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(except: :area2).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", true]]
    end

    it "allows for including certain content types" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(include: :OtherPage).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page2", true], ["/area2-page2", false]]
    end

    it "allows for rejecting certain content types" do
      @target = Page.new
      @area1_page2.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(exclude: Page).map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page2", true], ["/area2-page2", false]]
    end

    it "shows children of the public root when rendering a private root" do
      @target = Page.create_root "error"
      @context = @context_class.new(@target)
      result = @context.navigation.map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", false], ["/area2-page1", false], ["/area2-page2", false]]
    end

    it "shows children of the public root when rendering a private page" do
      root = Page.create_root "error"
      @target = Page.new
      root.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation.map { |p, a| [p.path, a]}
      result.must_equal [["/area1-page1", false], ["/area1-page2", false], ["/area2-page1", false], ["/area2-page2", false]]
    end

    it "doesn't throw errors when attempting to render from a non-existant parent" do
      root = Page.create_root "error"
      @target = Page.new
      root.area2 << @target
      @target.save.reload
      @context = @context_class.new(@target)
      result = @context.navigation(depth: 2).map { |p, a| [p.path, a]}
      result.must_equal []
    end
  end
end