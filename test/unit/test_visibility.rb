# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Visibility" do

  start do
    @site = setup_site
    Object.const_set :R, Class.new(Page)
    Object.const_set :P, Class.new(Page)
    Object.const_set :E, Class.new(Piece)
    Object.const_set :MyAlias, Class.new(Piece)
    ::R.box :pages
    P.box :things
    E.box :pages
    MyAlias.alias_of ::E

    Content.delete

    @root = R.new(uid: 'root')
    2.times do |i|
      c = P.new(uid: i, slug: "#{i}")
      @root.pages << c
      4.times do |j|
        d = E.new(uid: "#{i}.#{j}")
        c.things << d
        2.times do |k|
          e = P.new(uid: "#{i}.#{j}.#{k}", slug: "#{i}-#{j}-#{k}")
          d.pages << e
          2.times do |l|
            e.things << E.new(uid: "#{i}.#{j}.#{k}.#{l}")
          end
          e.save
        end
      end
    end
    @root.save
    @root.reload
  end

  finish do
    Content.delete
    Object.send(:remove_const, :R)
    Object.send(:remove_const, :P)
    Object.send(:remove_const, :E)
    Object.send(:remove_const, :MyAlias)
    teardown_site(true, true)
  end

  def self.site
    @site
  end

  before do
    Content.count.must_equal 59
    @site = self.class.site
    @root = Content.root
    @child = Page.uid("0")
  end

  after do
    Content.update(hidden: false, hidden_origin: nil)
    teardown_site(false, false)
  end

  it "be visible by default" do
    assert @child.visible?
  end

  it "be hidable using #hide!" do
    @child.hide!
    refute @child.visible?
    assert @child.hidden?
  end

  it "be hidable using #visible=" do
    @child.visible = false
    refute @child.visible?
    assert @child.hidden?
  end

  it "hide child pages" do
    assert @child.page?
    @child.hide!
    @child.children.each do |child1|
      refute child1.visible?
      child1.hidden_origin.must_equal @child.id
      child1.children.each do |child2|
        refute child2.visible?
        child2.hidden_origin.must_equal @child.id
      end
    end
  end

  it "hide page content" do
    @child.hide!
    @child.reload
    Content::Piece.all.select { |f| f.visible? }.length.must_equal 20
    Piece.all.select do |f|
      f.page.ancestors.include?(@child) || f.page == @child
    end.each do |f|
      refute f.visible?
      f.hidden_origin.must_equal @child.id
    end
    Piece.all.select do | f |
      !f.page.ancestors.include?(@child) && f.page != @child
    end.each do |f|
      assert f.visible?
      f.hidden_origin.must_be_nil
    end
  end

  it "re-show all page content" do
    @child.hide!
    @child.show!
    @child.reload
    Content.all.each do |c|
      assert c.visible?
      c.hidden_origin.must_be_nil
    end
  end

  it "hide all descendents of page content" do
    piece = Content.first(uid: "0.0")
    f = E.new(uid: "0.0.X")
    piece.pages << f
    piece.save
    piece.reload
    piece.hide!

    Content.all.each do |c|
      if c.uid =~ /^0\.0/
        assert c.hidden?
        refute c.visible?
        if c.uid == "0.0"
          c.hidden_origin.must_be_nil
        else
          c.hidden_origin.must_equal piece.id
        end
      else
        refute c.hidden?
        c.hidden_origin.must_be_nil
      end
    end
    f.destroy
  end

  it "re-show all descendents of page content" do
    piece = Content.first(uid: "0.0")
    piece.hide!
    piece.show!
    Content.all.each do |c|
      assert c.visible?
      c.hidden_origin.must_be_nil
    end
  end

  it "know if something is hidden because its ancestor is hidden" do
    piece = Content.first(uid: "0.0")
    piece.hide!
    assert piece.showable?
    child = Content.first(uid: "0.0.0.0")
    refute child.visible?
    refute child.showable?
  end

  # showing something that is hidden because its ancestor is hidden shouldn't be possible
  it "stop hidden child content from being hidden" do
    piece = Content.first(uid: "0.0")
    piece.hide!
    child = Content.first(uid: "0.0.0.0")
    refute child.visible?
    lambda { child.show! }.must_raise(Spontaneous::NotShowable)
  end

  it "not reveal child content that was hidden before its parent" do
    piece1 = Content.first(uid: "0.0.0.0")
    piece2 = Content.first(uid: "0.0.0.1")
    parent = Content.first(uid: "0.0.0")
    piece1.owner.must_equal parent
    piece2.owner.must_equal parent
    piece1.container.must_equal parent.things
    piece2.container.must_equal parent.things
    piece1.hide!
    parent.hide!
    refute parent.reload.visible?
    refute piece1.reload.visible?
    refute piece2.reload.visible?
    piece1.hidden_origin.must_be :blank?
    piece2.hidden_origin.must_equal parent.id
    parent.show!
    assert parent.reload.visible?
    assert piece2.reload.visible?
    refute piece1.reload.visible?
  end


  it "add child content with a visibility inherited from their parent" do
    page = P.first
    page.hide!
    page.reload
    piece = E.new
    page.things << piece
    page.save
    piece.reload
    assert piece.hidden?
    page.show!
    refute piece.reload.hidden?
    piece.destroy
  end

  describe "root" do
    it "should not be hidable" do
      assert @root.is_root?
      lambda { @root.visible = false }.must_raise(RuntimeError)
      lambda { @root.hide! }.must_raise(RuntimeError)
      assert @root.visible?
    end
  end

  describe "top-level searches" do
    it "return a list of visible pages" do
      @root.pages.first.hide!
      P.visible.count.must_equal 9
    end
  end
  describe "visibility scoping" do
    it "prevent inclusion of hidden content" do
      @uid = '0'
      @page = Page.uid(@uid)
      @page.hide!
      @page.reload
      Page.path("/0").must_equal @page
      Content.with_visible do
        assert Content.visible_only?
        Page.uid(@uid).must_be :blank?
        Page.path("/0").must_be :blank?
        Page.uid('0.0.0').must_be :blank?
      end
    end

    it "only show visible pieces" do
      page = Content.first(uid: "1")
      page.contents.length.must_equal 4
      page.things.contents.length.must_equal 4
      page.things.count.must_equal 4
      page.contents.first.hide!
      page.reload
      Content.with_visible do
        page.contents.length.must_equal 3
        page.contents.first.id.wont_equal page.id
        assert page.contents.first.first?
      end
    end

    it "stop modification of pieces" do
      page = Content.first(uid: "1")
      Content.with_visible do
        p = Piece.new
        lambda { page.things << p }.must_raise(Spontaneous::ReadOnlyScopeModificationError)
        lambda { p.destroy }.must_raise(Spontaneous::ReadOnlyScopeModificationError)
      end
    end

    it "ensure that no hidden content can be returned" do
      @root.reload
      @root.children.first.children.length.must_equal 8
      @root.children.first.contents.first.hide!
      @root.reload
      Content.with_visible do
        @root.children.first.children.length.must_equal 6
      end
    end

    it "hide pages without error" do
      @root.pages.first.hide!
      @root.reload
      Content.with_visible do
        _pieces = @root.pages.contents.map { |p| p }
      end
    end
  end

  describe "aliases" do
    after do
      MyAlias.delete
    end

    it "be initalized as invisible if their target is invisible" do
      target = E.create(uid: 'X')
      target.hide!
      al = MyAlias.create(target: target)
      refute al.visible?
    end

    it "be initalized as invisible with their target's hidden origin if their target is invisible" do
      parent = P.first(uid: '1')
      target = E.first(uid: '1.1')
      parent.hide!
      target.reload.hidden_origin.must_equal parent.id
      a = MyAlias.create(target: target)
      refute a.visible?
      a.hidden_origin.must_equal parent.id
    end


    it "be made visible along with their target if added when target is hidden" do
      target = E.first(uid: '1.1')
      target.hide!
      al = MyAlias.create(target: target)
      refute al.reload.visible?
      target.show!
      assert al.reload.visible?
    end

    it "be filtered by visibility when doing reverse lookup" do
      page = P.first(uid: '1')
      target = E.first(uid: '1.1')
      al1 = MyAlias.create(target: target)
      page.things << al1
      al2 = MyAlias.create(target: target).reload
      page.things << al2
      al1.hide!
      al1.reload
      al2.reload
      target.reload
      sort = proc { |e1, e2| e1.id <=> e2.id }
      _al = target.aliases.sort(&sort)
      Set.new(target.aliases).must_equal Set.new([al1, al2])
      target.reload
      Content.with_visible do
        target.aliases.must_equal [al2]
      end
    end

    it "show as 'hidden' if their target is deleted" do
      parent = E.first(uid: "1.1")
      target = P.new
      parent.pages << target
      parent.save
      al1 = MyAlias.create(target: target)
      P.filter(id: target.id).delete
      refute al1.reload.visible?
      target.destroy
    end

    describe 'nested visibility' do

      # Given the following structure, where 'a means "alias of a" etc
      # then hiding a should also hide 'a, b, c, 'c, d, e and 'e
      #   ┌───┐
      #   │ a │
      #   └───┘
      #     ▲
      #     │
      #   ┌───┐┌───┐┌───┐
      #   │'a ││ b ││ c │
      #   └───┘└───┘└───┘
      #               ▲
      #     ──────────┘
      #   ┌───┐┌───┐┌───┐
      #   │'c ││ d ││ e │
      #   └───┘└───┘└───┘
      #               ▲
      #     ──────────┘
      #   ┌───┐
      #   │'e │
      #   └───┘
      before do
        P.box :pages
        class PageAlias < ::Page
          alias_of ::P
          box :pages
        end
        a = P.new(slug: 'A')
        @root.pages << a

        _a = PageAlias.new(target: a)

        @root.pages << _a
        b = P.new(slug: 'B')
        _a.pages << b
        c = P.new(slug: 'C')
        b.pages << c

        _c = PageAlias.new(target: c)
        @root.pages << _c
        d = P.new(slug: 'D')
        _c.pages << d
        e = P.new(slug: 'E')
        d.pages << e
        _e = PageAlias.new(target: e)
        @root.pages << _e
        @hierarchy = [a, _a, b, c, _c, d, e, _e]
      end

      it 'should cascade visibility across alias trees' do
        a, _a, b, c, _c, d, e, _e = @hierarchy

        affected = a.hide!

        [_a, b, c, _c, d, e, _e].each do |page|
          assert page.reload.hidden?, "Page #{page.class}#{page.path} should be hidden"
          assert page.hidden_origin == a.id, "Hidden origin should be #{a.id}, but is #{page.hidden_origin}"
        end

        affected.map(&:id).must_equal [a, _a, b, c, _c, d, e, _e].map(&:id)

        affected = a.show!

        [_a, b, c, _c, d, e, _e].each do |page|
          refute page.reload.hidden?, "Page #{page.class}#{page.path} should be visible"
          assert page.hidden_origin.nil?, "Hidden origin should be nil, but is #{page.hidden_origin}"
        end

        affected.map(&:id).must_equal [a, _a, b, c, _c, d, e, _e].map(&:id)
      end

      it 'should return a list of affected content with the updated visibility state' do
        a, * = @hierarchy

        affected = a.hide!

        affected.each do |x|
          assert x.hidden?
        end

        affected = a.show!

        affected.each do |x|
          assert x.visible?
        end
      end

      it 'should cascade visibility when an item has multiple aliases' do
        a, _a, b, c, _c, _, _, _e = @hierarchy
        __c = PageAlias.new(target: c)
        b.pages << __c
        f = P.new(slug: 'F')
        __c.pages << f
        g = P.new(slug: 'G')
        f.pages << g
        a.hide!
        assert __c.reload.hidden?
        assert __c.hidden_origin == a.id
        assert f.reload.hidden?
        assert f.hidden_origin == a.id
        assert g.reload.hidden?
        assert g.hidden_origin == a.id
      end

      it 'should cascade visibility changes only after saving' do
        a, _a, b, c, _c, d, e, _e = @hierarchy
        a.visible = false
        [_a, b, c, _c, d, e, _e].each do |page|
          refute page.reload.hidden?, "Page #{page.class}#{page.path} should be visible"
          assert page.hidden_origin.nil?, "Hidden origin should be nil, but is #{page.hidden_origin}"
        end
        a.save
        [_a, b, c, _c, d, e, _e].each do |page|
          assert page.reload.hidden?, "Page #{page.class}#{page.path} should be hidden"
          assert page.hidden_origin == a.id, "Hidden origin should be #{a.id}, but is #{page.hidden_origin}"
        end
        a.visible = true
        [_a, b, c, _c, d, e, _e].each do |page|
          assert page.reload.hidden?, "Page #{page.class}#{page.path} should be hidden"
          assert page.hidden_origin == a.id, "Hidden origin should be #{a.id}, but is #{page.hidden_origin}"
        end
        a.save
        [_a, b, c, _c, d, e, _e].each do |page|
          refute page.reload.hidden?, "Page #{page.class}#{page.path} should be visible"
          assert page.hidden_origin.nil?, "Hidden origin should be nil, but is #{page.hidden_origin}"
        end
      end
    end
  end
end
