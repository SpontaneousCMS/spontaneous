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

  context "Tree" do
    setup do
      Content.delete
    end
    should "be constructed for children" do
      p = Page.create
      q = Page.new
      p.root?.should be_true
      p << q
      p.entries.first.proxy_class.should == Spontaneous::PageEntry
      p.save
      q.save
      p.children.should == [q]
      q.parent.id.should == p.id
      q.path.should == "/#{q.slug}"
      r = Page.new
      q << r
      q.save
      r.save
      q.children.should == [r]
      r.parent.id.should == q.id
      r.path.should == "/#{q.slug}/#{r.slug}"
    end
  end
end
