# encoding: UTF-8

require 'test_helper'


class ContentTest < Test::Unit::TestCase

  context "Single table inheritance" do
    setup do
      Content.delete
      class ::PageClass1 < Page; end
      class ::PageClass11 < ::PageClass1; end
      class ::PageClass111 < ::PageClass1; end
      class ::PageClass2 < Page; end
      class ::PageClass22 < PageClass2; end

      @page1 = PageClass1.create.reload
      @page11 = PageClass11.create.reload
      @page111 = PageClass111.create.reload
      @page2 = PageClass2.create.reload
      @page22 = PageClass22.create.reload

      class ::FacetClass1 < Facet; end
      class ::FacetClass11 < FacetClass1; end
      class ::FacetClass111 < FacetClass11; end
      class ::FacetClass2 < Facet; end
      class ::FacetClass22 < FacetClass2; end

      @facet1 = FacetClass1.create.reload
      @facet11 = FacetClass11.create.reload
      @facet111 = FacetClass111.create.reload
      @facet2 = FacetClass2.create.reload
      @facet22 = FacetClass22.create.reload
    end

    teardown do
      [
        :PageClass1, :PageClass11, :PageClass111, :PageClass2, :PageClass22,
        :FacetClass1, :FacetClass11, :FacetClass111, :FacetClass2, :FacetClass22
      ].each do |klass|
        Object.send(:remove_const, klass)
      end
    end

    should "correctly type subclasses found via Content" do
      Content.all.map { |c| c.class }.should == \
        [PageClass1, PageClass11, PageClass111, PageClass2, PageClass22,
          FacetClass1, FacetClass11, FacetClass111, FacetClass2, FacetClass22]
      Content.all.should == \
        [@page1, @page11, @page111, @page2, @page22,
          @facet1, @facet11, @facet111, @facet2, @facet22]
    end

    context "Pages" do

      should "type subclasses found via Page" do
        Page.all.map { |c| c.class }.should == \
          [PageClass1, PageClass11, PageClass111, PageClass2, PageClass22]
        Page.all.should == [@page1, @page11, @page111, @page2, @page22]
      end

      should "only find instances of a single class when searching via that subclass" do
        PageClass1.all.map { |c| c.class }.should == [PageClass1]
        PageClass1.all.should == [@page1]
        PageClass11.all.should == [@page11]
      end
    end

    context "Facets" do
      should "type subclasses found via Page" do
        Facet.all.map { |c| c.class }.should == \
          [FacetClass1, FacetClass11, FacetClass111, FacetClass2, FacetClass22]
        Facet.all.should == [@facet1, @facet11, @facet111, @facet2, @facet22]
      end

      should "only find instances of a single class when searching via that subclass" do
        FacetClass1.all.map { |c| c.class }.should == [FacetClass1]
        FacetClass1.all.should == [@facet1]
        FacetClass11.all.should == [@facet11]
        FacetClass2.all.map { |c| c.class }.should == [FacetClass2]
        FacetClass2.all.should == [@facet2]
        FacetClass22.all.should == [@facet22]
      end
    end
  end
end
