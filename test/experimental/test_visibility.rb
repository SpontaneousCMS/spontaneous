# encoding: UTF-8

require 'test_helper'


class VisibilityTest < Test::Unit::TestCase

  context "Content" do
    setup do
      Spontaneous.database = DB
      Content.delete
      @root = Page.new(:uid => 'root')
      2.times do |i|
        c = Page.new(:uid => i, :slug => "#{i}")
        @root << c
        4.times do |j|
          d = Facet.new(:uid => "#{i}.#{j}")
          c << d
          2.times do |k|
            e = Page.new(:uid => "#{i}.#{j}.#{k}", :slug => "#{i}-#{j}-#{k}")
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
        child1.hidden_origin.should == @child.id
        child1.children.each do |child2|
          child2.visible?.should be_false
          child2.hidden_origin.should == @child.id
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
        f.hidden_origin.should == @child.id
      end
      Facet.all.select do | f |
        !f.page.ancestors.include?(@child) && f.page != @child
      end.each do |f|
        f.visible?.should be_true
        f.hidden_origin.should be_nil
      end
    end

    should "re-show all page content" do
      @child.hide!
      @child.show!
      @child.reload
      Content.all.each do |c|
        c.visible?.should be_true
        c.hidden_origin.should be_nil
      end
    end

    should "hide all descendents of page content" do
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
            c.visible?.should be_false
            c.hidden_origin.should be_nil
          else
            c.visible?.should be_false
            c.hidden_origin.should == facet.id
          end
        else
          c.hidden?.should be_false
          c.hidden_origin.should be_nil
        end
      end

    end

    should "re-show all descendents of page content" do
      facet = Content.first(:uid => "0.0")
      facet.hide!
      facet.show!
      Content.all.each do |c|
        c.visible?.should be_true
        c.hidden_origin.should be_nil
      end
    end

    should "know if something is hidden because its ancestor is hidden" do
      facet = Content.first(:uid => "0.0")
      facet.hide!
      facet.showable?.should be_true
      child = Content.first(:uid => "0.0.0.0")
      child.visible?.should be_false
      child.showable?.should be_false
    end

    # showing something that is hidden because its ancestor is hidden shouldn't be possible
    should "stop hidden child content from being hidden" do
      facet = Content.first(:uid => "0.0")
      facet.hide!
      child = Content.first(:uid => "0.0.0.0")
      child.visible?.should be_false
      lambda { child.show! }.should raise_error(Spontaneous::NotShowable)
    end

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
      end

      should "prevent inclusion of hidden content" do
        @uid = '0'
        @page = Page.uid(@uid)
        @page.hide!
        @page.reload
        # Spontaneous.database.logger = ::Logger.new($stdout)
        Page.path("/0").should == @page
        Content.with_visible do
          Content.visible_only?.should be_true
          Page.uid(@uid).should be_blank
          Page.path("/0").should be_blank
          Page.uid('0.0.0').should be_blank
        end
      end

      should "only show visibile entries" do
        page = Content.first(:uid => "1")
        page.entries.length.should == 4
        page.entries.first.hide!
        page.reload
        Content.with_visible do
          page.entries.length.should == 3
        end
      end

      should "stop modification of entries" do
        page = Content.first(:uid => "1")
        Content.with_visible do
          lambda { page.entries << Facet.new }.should raise_error(TypeError)
          lambda { page << Facet.new }.should raise_error(TypeError)
        end
      end
    end
  end
end
