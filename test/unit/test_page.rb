require 'test_helper'


class PageTest < Test::Unit::TestCase
  include Spontaneous

  context "Root page" do
    setup do
      Content.delete
    end
    should "be created by first page insert" do
      p = Page.create
      p.root?.should be_true
      p.path.should == "/"
      p.slug.should == ""
      p.parent.should be_nil
    end

    should "be a singleton" do
      p = Page.create
      p.root?.should be_true
      q = Page.create
      q.root?.should be_false
    end
  end

  context "Slugs" do
    setup do
    end

    should "be generated if missing" do
      p = Page.new
      p.slug.should_not == ""
    end

    should "be made URL safe" do
      p = Page.new
      p.slug = " something's illegal and ugly!!"
      p.slug.should == "somethings-illegal-and-ugly"
      p.save
      p.reload
      p.slug.should == "somethings-illegal-and-ugly"
    end
  end

  context "Pages in tree" do
    setup do
      Content.delete
      @p = Page.create
      @q = Page.new
      @r = Page.new
      @s = Page.new
      @p << @q
      @q << @r
      @q << @s
      @p.save
      @q.save
      @r.save
      @s.save
    end

    should "have the right entry classes" do
      @p.entries.first.proxy_class.should == Spontaneous::PageEntry
      @q.entries.first.proxy_class.should == Spontaneous::PageEntry
    end

    should "have a reference to their parent" do
      @p.parent.should be_nil
      @q.parent.should === @p
      @r.parent.should === @q
      @s.parent.should === @q
    end
    should "have a list of their children" do
      @p.children.should == [@q]
      @q.children.should == [@r, @s]
      @r.children.should == []
      @s.children.should == []
    end
    should "keep track of their depth" do
      @p.depth.should == 0
      @q.depth.should == 1
      @r.depth.should == 2
      @s.depth.should == 2
    end

    should "have correct paths" do
      @p.path.should == "/"
      @q.path.should == "/#{@q.slug}"
      @r.path.should == "/#{@q.slug}/#{@r.slug}"
      @s.path.should == "/#{@q.slug}/#{@s.slug}"
    end

    should "all have a reference to the root node" do
      @p.root?.should be_true
      @p.root.should === @p
      @q.root.should === @p
      @r.root.should === @p
      @s.root.should === @p
    end
  end
end
