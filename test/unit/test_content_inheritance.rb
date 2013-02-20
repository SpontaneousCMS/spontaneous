# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "ContentInheritance" do

  describe "Single table inheritance" do
    before do
      @site = setup_site

      Content.delete
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

    after do
      [ :PageClass1, :PageClass11, :PageClass111, :PageClass2, :PageClass22,
        :PieceClass1, :PieceClass11, :PieceClass111, :PieceClass2, :PieceClass22
      ].each do |klass|
        Object.send(:remove_const, klass)
      end
      teardown_site
    end

    it "correctly type subclasses found via Content" do
      Set.new(Content.all.map { |c| c.class }).must_equal \
        Set.new([PageClass1, PageClass11, PageClass111, PageClass2, PageClass22,
          PieceClass1, PieceClass11, PieceClass111, PieceClass2, PieceClass22])
      Set.new(Content.all).must_equal \
        Set.new([@page1, @page11, @page111, @page2, @page22,
          @piece1, @piece11, @piece111, @piece2, @piece22])
    end

    describe "Pages" do

      it "type subclasses found via Content::Page" do
        Set.new(Content::Page.all.map { |c| c.class }).must_equal \
          Set.new([PageClass1, PageClass11, PageClass111, PageClass2, PageClass22])
        Set.new(Content::Page.all).must_equal Set.new([@page1, @page11, @page111, @page2, @page22])
      end

      it "only find instances of a single class when searching via that subclass" do
        PageClass1.all.map { |c| c.class }.must_equal [PageClass1]
        PageClass2.all.map { |c| c.class }.must_equal [PageClass2]
        PageClass22.all.map { |c| c.class }.must_equal [PageClass22]
        PageClass1.all.must_equal [@page1]
        PageClass11.all.must_equal [@page11]
      end
    end

    describe "Pieces" do
      it "type subclasses found via Spontaneous::Piece" do
        Set.new(Content::Piece.all.map { |c| c.class }).must_equal \
          Set.new([PieceClass1, PieceClass11, PieceClass111, PieceClass2, PieceClass22])
        Set.new(Content::Piece.all).must_equal Set.new([@piece1, @piece11, @piece111, @piece2, @piece22])
      end

      it "only find instances of a single class when searching via that subclass" do
        PieceClass1.all.map { |c| c.class }.must_equal [PieceClass1]
        PieceClass1.all.must_equal [@piece1]
        PieceClass11.all.must_equal [@piece11]
        PieceClass2.all.map { |c| c.class }.must_equal [PieceClass2]
        PieceClass2.all.must_equal [@piece2]
        PieceClass22.all.must_equal [@piece22]
      end
    end
  end
end
