# encoding: UTF-8

require 'test_helper'


class FacetTest < Test::Unit::TestCase
  include Spontaneous

  context "Facets" do
    should "not be pages" do
      Facet.new.page?.should be_false
    end

    context "as page content" do
      setup do
        class ::Fridge < Facet; end
        @page = Page.create
        @f1 = Facet.new
        @page << @f1
        @f2 = Facet.new
        @f1 << @f2
        @f3 = Fridge.new
        @f2 << @f3

        @page.save
        @f1.save
        @f2.save
        @f3.save

        @page = Page[@page.id]
        @f1 = Facet[@f1.id]
        @f2 = Facet[@f2.id]
        @f3 = Content[@f3.id]
      end
      teardown do
        Object.send(:remove_const, :Fridge)
      end

      should "have a link to the page" do
        @f1.page.should == @page
        @f2.page.should == @page
        @f3.page.should == @page
      end

      should "have a link to their container" do
        @f1.container.should == @page
        @f2.container.should == @f1
        @f3.container.should == @f2
      end

      should "know their depth in the facet tree" do
        @f1.depth.should == 1
        @f2.depth.should == 2
        @f3.depth.should == 3
      end

      should "be available from their containing page" do
        @page.facets.length.should == 3
        @page.facets.should == [@f1, @f2, @f3]
        @page.facets.last.class.should == Fridge
      end

      should "have a link to their entries" do
        @f1.entry.should == @page.entries.first
        @f2.entry.should == @page.entries.first.entries.first
      end
    end
  end
end

