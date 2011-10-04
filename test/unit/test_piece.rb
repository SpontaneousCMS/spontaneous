# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class PieceTest < MiniTest::Spec
  include Spontaneous

  context "Pieces" do
    setup do
      Content.delete
      Spot::Schema.reset!
      class ::Piece < Spot::Piece; end
      class ::Page < Spot::Page; end
      class ::Fridge < ::Piece; end
    end

    teardown do
      Object.send(:remove_const, :Page)
      Object.send(:remove_const, :Piece)
      Object.send(:remove_const, :Fridge)
    end

    should "not be pages" do
      Piece.new.page?.should be_false
    end

    context "as page content" do
      setup do
        @page = ::Page.create
        @f1 = ::Piece.new
        @page << @f1
        @f2 = ::Piece.new
        @f1 << @f2
        @f3 = ::Fridge.new
        @f2 << @f3

        @page.save
        @f1.save
        @f2.save
        @f3.save

        @page = ::Page[@page.id]
        @f1 = ::Piece[@f1.id]
        @f2 = ::Piece[@f2.id]
        @f3 = Content[@f3.id]
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

      should "have a link to their pieces" do
        @f1.entry.should == @page.pieces.first
        @f2.entry.should == @page.pieces.first.pieces.first
      end
    end
  end
end

