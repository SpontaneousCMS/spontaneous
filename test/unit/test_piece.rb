# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Piece" do

  before do
    @site = setup_site
    Content.delete
    class ::Fridge < ::Piece; end
  end

  after do
    Object.send(:remove_const, :Fridge) rescue nil
    teardown_site
  end

  it "not be pages" do
    refute Piece.new.page?
  end

  describe "as page content" do
    before do
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

    it "have a link to the page" do
      @f1.page.must_equal @page
      @f2.page.must_equal @page
      @f3.page.must_equal @page
    end

    it "have a link to their box" do
      @f1.container.must_equal @page.things
      @f2.container.must_equal @f1.things
      @f3.container.must_equal @f2.things
    end

    it "have a link to their owner" do
      @f1.owner.must_equal @page
      @f2.owner.must_equal @f1
      @f3.owner.must_equal @f2
      @f1.parent.must_equal @page
      @f2.parent.must_equal @f1
      @f3.parent.must_equal @f2
    end

    it "return themselves as content_instance" do
      @f2.content_instance.must_equal @f2
    end

    it "know their depth in the piece tree" do
      @f1.depth.must_equal 1
      @f2.depth.must_equal 2
      @f3.depth.must_equal 3
    end

    it "be available from their containing page" do
      @page.content.length.must_equal 3
      Set.new(@page.content).must_equal Set.new([@f1, @f2, @f3])
      Set.new(@page.content.map(&:class)).must_equal Set.new([::Piece, ::Piece, Fridge])
    end

    it "have a link to their pieces" do
      @f1.entry.must_equal @page.contents.first
      @f2.entry.must_equal @page.contents.first.contents.first
    end
  end
end

