# encoding: UTF-8

require 'test_helper'


class PieceTest < Test::Unit::TestCase
  include Spontaneous

  context "Pieces" do
    should "not be pages" do
      Piece.new.page?.should be_false
    end

    context "as page content" do
      setup do
        class ::Fridge < Piece; end
        @page = Page.create
        @f1 = Piece.new
        @page << @f1
        @f2 = Piece.new
        @f1 << @f2
        @f3 = Fridge.new
        @f2 << @f3

        @page.save
        @f1.save
        @f2.save
        @f3.save

        @page = Page[@page.id]
        @f1 = Piece[@f1.id]
        @f2 = Piece[@f2.id]
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

      should "know their depth in the piece tree" do
        @f1.depth.should == 1
        @f2.depth.should == 2
        @f3.depth.should == 3
      end

      should "be available from their containing page" do
        @page.content.length.should == 3
        @page.content.should == [@f1, @f2, @f3]
        @page.content.last.class.should == Fridge
      end

      should "have a link to their entries" do
        @f1.entry.should == @page.entries.first
        @f2.entry.should == @page.entries.first.entries.first
      end
    end
  end
end

