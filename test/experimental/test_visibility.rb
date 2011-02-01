# encoding: UTF-8

require 'test_helper'


class VisibilityTest < Test::Unit::TestCase

  context "Content" do
    setup do
      Spontaneous.database = DB
      Content.delete
      @root = Page.new(:uid => 'root')
      2.times do |i|
        c = Page.new(:uid => i)
        @root << c
        4.times do |j|
          d = Facet.new(:uid => "#{i}.#{j}")
          c << d
          2.times do |k|
            e = Page.new(:uid => "#{i}.#{j}.#{k}")
            d << e
            2.times do |l|
              e << Facet.new(:uid => "#{i}.#{j}.#{k}.#{l}")
            end
            d.save
          end
        end
        c.save
      end
      @root.save
      @root.reload
      @child = Page.uid("0")
    end

    teardown do
      Spontaneous.database.logger = nil
      Content.delete
    end

    should "be visible by default" do
      @child.visible?.should be_true
    end

    should "be hidable using #hide!" do
      @child.hide!
      @child.visible?.should be_false
      @child.hidden?.should be_true
    end

    should "be hidable using #visible=" do
      @child.visible = false
      @child.visible?.should be_false
      @child.hidden?.should be_true
    end

    should "hide child pages" do
      @child.page?.should be_true
      @child.hide!
      @child.children.each do |child1|
        child1.visible?.should be_false
        child1.children.each do |child2|
          child2.visible?.should be_false
        end
      end
    end

    should "hide page content" do
      @child.hide!
      @child.reload
      Facet.all.select { |f| f.visible? }.length.should == 20
      Facet.all.select do |f|
        f.page.ancestors.include?(@child) || f.page == @child
      end.each do |f|
        f.visible?.should be_false
      end
      Facet.all.select do | f |
        !f.page.ancestors.include?(@child) && f.page != @child
      end.each do |f|
        f.visible?.should be_true
      end
    end

    should "hide all descendents of page content" do
      Spontaneous.database.logger = ::Logger.new($stdout)
      facet = Content.first(:uid => "0.0")
      f = Facet.new(:uid => "0.0.X")
      facet << f
      facet.save
      facet.reload
      facet.hide!

      Content.all.each do |c|
        if c.uid =~ /^0\.0/
          c.hidden?.should be_true
          if c.uid == "0.0"
            c.assigned_visible.should be_false
            c.inherited_visible.should be_true
          else
            c.assigned_visible.should be_true
            c.inherited_visible.should be_false
          end
        else
          c.hidden?.should be_false
        end
      end
    end

    # hiding something that is hidden because its ancestor is hidden shouldn't be possible
    should "stop hidden child content from being hidden"

    context "root" do
      should "should not be hidable" do
        @root.is_root?.should be_true
        lambda { @root.visible = false }.should raise_error
        lambda { @root.hide! }.should raise_error
        @root.visible?.should be_true
      end
    end

    context "visibility scoping" do
      setup do
        @uid = '0.0'
        @page = Page.uid(@uid)
        @page.hide!
        @page.reload
      end

      should "xx prevent inclusion of hidden content" do
        Content.with_visible do
          Page.uid(@uid).should be_nil
        end
      end
    end
  end
end
