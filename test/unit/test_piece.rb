# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class PieceTest < MiniTest::Spec
  include Spontaneous

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Pieces" do
    setup do
      Content.delete
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
        ::Page.box :things
        ::Piece.box :things
        @page = ::Page.create
        @f1 = ::Piece.new
        @page.things << @f1
        @f2 = ::Piece.new
        @f1.things << @f2
        @f3 = ::Fridge.new
        @f2.things << @f3

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

      should "have a link to their box" do
        @f1.container.should == @page.things
        @f2.container.should == @f1.things
        @f3.container.should == @f2.things
      end

      should "have a link to their owner" do
        @f1.owner.should == @page
        @f2.owner.should == @f1
        @f3.owner.should == @f2
        @f1.parent.should == @page
        @f2.parent.should == @f1
        @f3.parent.should == @f2
      end

      should "know their depth in the piece tree" do
        @f1.depth.should == 1
        @f2.depth.should == 2
        @f3.depth.should == 3
      end

      should "be available from their containing page" do
        @page.content.length.should == 3
        Set.new(@page.content).should == Set.new([@f1, @f2, @f3])
        Set.new(@page.content.map(&:class)).should == Set.new([::Piece, ::Piece, Fridge])
      end

      should "have a link to their pieces" do
        @f1.entry.should == @page.pieces.first
        @f2.entry.should == @page.pieces.first.pieces.first
      end
    end
  end
end

