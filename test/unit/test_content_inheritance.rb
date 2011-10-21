# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ContentInheritanceTest < MiniTest::Spec

  context "Single table inheritance" do
    setup do
      @site = setup_site

      Content.delete
      class ::Page < Spontaneous::Page; end
      class ::PageClass1 < ::Page; end
      class ::PageClass11 < ::PageClass1; end
      class ::PageClass111 < ::PageClass1; end
      class ::PageClass2 < ::Page; end

      class ::PageClass22 < PageClass2; end
      @page1 = PageClass1.create.reload
      @page11 = PageClass11.create.reload
      @page111 = PageClass111.create.reload
      @page2 = PageClass2.create.reload
      @page22 = PageClass22.create.reload

      class ::Piece < Spontaneous::Piece; end
      class ::PieceClass1 < ::Piece; end
      class ::PieceClass11 < PieceClass1; end
      class ::PieceClass111 < PieceClass11; end
      class ::PieceClass2 < ::Piece; end
      class ::PieceClass22 < PieceClass2; end

      @piece1 = PieceClass1.create.reload
      @piece11 = PieceClass11.create.reload
      @piece111 = PieceClass111.create.reload
      @piece2 = PieceClass2.create.reload
      @piece22 = PieceClass22.create.reload
    end

    teardown do
      [
        :Page, :Piece,
        :PageClass1, :PageClass11, :PageClass111, :PageClass2, :PageClass22,
        :PieceClass1, :PieceClass11, :PieceClass111, :PieceClass2, :PieceClass22
      ].each do |klass|
        Object.send(:remove_const, klass)
      end
      teardown_site
    end

    should "aaa correctly type subclasses found via Content" do
      Content.all.map { |c| c.class }.should == \
        [PageClass1, PageClass11, PageClass111, PageClass2, PageClass22,
          PieceClass1, PieceClass11, PieceClass111, PieceClass2, PieceClass22]
      Content.all.should == \
        [@page1, @page11, @page111, @page2, @page22,
          @piece1, @piece11, @piece111, @piece2, @piece22]
    end

    context "Pages" do

      should "type subclasses found via Page" do
        ::Page.all.map { |c| c.class }.should == \
          [PageClass1, PageClass11, PageClass111, PageClass2, PageClass22]
        ::Page.all.should == [@page1, @page11, @page111, @page2, @page22]
      end

      should "type subclasses found via Spontaneous::Page" do
        Spontaneous::Page.all.map { |c| c.class }.should == \
          [PageClass1, PageClass11, PageClass111, PageClass2, PageClass22]
        Spontaneous::Page.all.should == [@page1, @page11, @page111, @page2, @page22]
      end

      should "only find instances of a single class when searching via that subclass" do
        PageClass1.all.map { |c| c.class }.should == [PageClass1]
        PageClass2.all.map { |c| c.class }.should == [PageClass2]
        PageClass22.all.map { |c| c.class }.should == [PageClass22]
        PageClass1.all.should == [@page1]
        PageClass11.all.should == [@page11]
      end
    end

    context "Pieces" do
      should "type subclasses found via Spontaneous::Piece" do
        Spontaneous::Piece.all.map { |c| c.class }.should == \
          [PieceClass1, PieceClass11, PieceClass111, PieceClass2, PieceClass22]
        Spontaneous::Piece.all.should == [@piece1, @piece11, @piece111, @piece2, @piece22]
      end
      should "type subclasses found via Piece" do
        ::Piece.all.map { |c| c.class }.should == \
          [PieceClass1, PieceClass11, PieceClass111, PieceClass2, PieceClass22]
        ::Piece.all.should == [@piece1, @piece11, @piece111, @piece2, @piece22]
      end

      should "only find instances of a single class when searching via that subclass" do
        PieceClass1.all.map { |c| c.class }.should == [PieceClass1]
        PieceClass1.all.should == [@piece1]
        PieceClass11.all.should == [@piece11]
        PieceClass2.all.map { |c| c.class }.should == [PieceClass2]
        PieceClass2.all.should == [@piece2]
        PieceClass22.all.should == [@piece22]
      end
    end
  end
end
