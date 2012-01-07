# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class PageTest < MiniTest::Spec
  include Spontaneous

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "All pages" do
    # should "have a pre-defined 'title' field" do
    #   p = Page.new
    #   p.field?(:title).should be_true
    #   p.title.value.should == "New Page"
    # end
  end
  context "Pages:" do
    setup do
      Content.delete
      class Page < Spot::Page
        field :title, :string
      end
      class Piece < Spontaneous::Piece; end
    end
    teardown do
      PageTest.send(:remove_const, :Page)
      PageTest.send(:remove_const, :Piece)
    end
    context "Root page" do
      setup do
      end
      should "be created by first page insert" do
        p = Page.create
        p.root?.should be_true
        p.path.should == "/"
        p.slug.should == ""
        p.parent.should be_nil
      end

      should "be a singleton" do
        p = Page.create
        p.root?.should be_true
        q = Page.create
        q.root?.should be_false
      end
    end

    context "Slugs" do
      setup do
      end

      should "be generated if missing" do
        o = Page.create
        p = Page.create
        p.slug.should_not == ""
        p.save
        p.reload.slug.should_not == ""
      end

      should "be made URL safe" do
        o = Page.create
        p = Page.create
        p.slug = " something's illegal and ugly!!"
        p.slug.should == "somethings-illegal-and-ugly"
        p.save
        p.reload.slug.should == "somethings-illegal-and-ugly"
      end

      should "be set from title if using generated slug" do
        r = Page.create
        slug = Page.generate_default_slug
        Page.stubs(:generate_default_slug).returns(slug)
        o = Page.create(:title => "New Page")
        p = Page.create(:title => "New Page")
        o.slug.should == slug
        r << o
        o.save
        o = Page[o.id]
        o.slug.should == slug
        o << p
        o.save
        o = Page[o.id]
        o.slug.should == slug
        o.title = "New Title"
        o.save
        o.reload
        o.slug.should == "new-title"
        o.title = "Another Title"
        o.save
        o.reload
        o.slug.should == "new-title"
      end

      should "not be longer than 255 chars" do
        o = Page.create
        long_slug = (["bang"]*100)
        o.slug = long_slug.join(' ')
        o.slug.length.should == 255
        o.slug.should == long_slug.join('-')[0..254]
      end
    end

    context "Pages in tree" do
      setup do
        Content.delete
        @p = Page.create
        @p.root?.should be_true
        @q = Page.new
        @r = Page.new
        @s = Page.new
        @t = Page.new
        @p << @q
        @q << @r
        @q << @s
        @s << @t
        @p.save
        @q.save
        @r.save
        @s.save
        @t.save
        # doing this means that the == tests work below
        @p = Page[@p.id]
        @q = Page[@q.id]
        @r = Page[@r.id]
        @s = Page[@s.id]
        @t = Page[@t.id]
      end

      should "have a reference to their parent" do
        @p.parent.should be_nil
        @q.parent.should === @p
        @r.parent.should === @q
        @s.parent.should === @q
        @t.parent.should === @s
      end
      should "have a reference to their owner" do
        @p.owner.should be_nil
        @q.owner.should === @p
        @r.owner.should === @q
        @s.owner.should === @q
        @t.owner.should === @s
      end

      should "return nil for their container" do
        @p.container.should be_nil
        @q.container.should be_nil
        @r.container.should be_nil
        @s.container.should be_nil
        @t.container.should be_nil
      end
      should "return nil for their box" do
        @p.box.should be_nil
        @q.box.should be_nil
        @r.box.should be_nil
        @s.box.should be_nil
        @t.box.should be_nil
      end

      should "have a list of their children" do
        @p.children.should == [@q]
        @q.children.should == [@r, @s]
        @r.children.should == []
        @s.children.should == [@t]
        @t.children.should == []
      end

      should "have a reference to themselves as page" do
        @p.page.should == @p
        @q.page.should == @q
        @r.page.should == @r
        @s.page.should == @s
        @t.page.should == @t
      end
      should "keep track of their depth" do
        @p.depth.should == 0
        @q.depth.should == 1
        @r.depth.should == 2
        @s.depth.should == 2
        @t.depth.should == 3
      end

      should "have the correct page hierarchy" do
        Page.box :things1
        Page.box :things2
        a = Page.new
        c = Page.new
        d = Page.new
        e = Page.new
        a.things1 << c
        a.things2 << d
        a.things2 << e
        a.save
        a.reload
        c.reload
        d.reload
        e.reload
        c.parent.should == a
        d.parent.should == a
        e.parent.should == a
        c.content_ancestors.should == [a, a.things1]
        d.content_ancestors.should == [a, a.things2]
        e.content_ancestors.should == [a, a.things2]
        c.page_order_string.should == "00000.00000"
        d.page_order_string.should == "00001.00000"
        e.page_order_string.should == "00001.00001"
      end

      should "have the correct page hierarchy for pages within pieces" do
        Page.box :things
        Piece.box :pages
        a = Page.new
        b = Piece.new
        a.things << b
        c = Page.new
        d = Page.new
        b.pages << c
        b.pages << d
        a.save
        a.reload
        b.reload
        c.reload
        d.reload
        c.parent.should == a
        c.content_ancestors.should == [a, a.things, b, b.pages]
        c.page_order_string.should == "00000.00000.00000.00000"
        d.page_order_string.should == "00000.00000.00000.00001"
      end

      should "have correct paths" do
        @p.path.should == "/"
        @q.path.should == "/#{@q.slug}"
        @r.path.should == "/#{@q.slug}/#{@r.slug}"
        @s.path.should == "/#{@q.slug}/#{@s.slug}"
        @t.path.should == "/#{@q.slug}/#{@s.slug}/#{@t.slug}"
      end

      should "all have a reference to the root node" do
        # @p.root?.should be_true
        @p.root.should === @p
        @q.root.should === @p
        @r.root.should === @p
        @s.root.should === @p
        @t.root.should === @p
      end

      should "have correct ancestor paths" do
        @p.ancestor_path.should == []
        @q.ancestor_path.should == [@p.id]
        @r.ancestor_path.should == [@p.id, @q.id]
        @s.ancestor_path.should == [@p.id, @q.id]
        @t.ancestor_path.should == [@p.id, @q.id, @s.id]
      end
      should "know their ancestors" do
        # must be a better way to test these arrays
        @p.ancestors.should === []
        @q.ancestors.should === [@p]
        @r.ancestors.should == [@p, @q]
        @s.ancestors.should == [@p, @q]
        @t.ancestors.should === [@p, @q, @s]
      end

      should "know their generation" do
        @r.generation.should == [@r, @s]
        @s.generation.should == [@r, @s]
      end

      should "know their siblings" do
        @r.siblings.should == [@s]
        @s.siblings.should == [@r]
      end

      should "always have the right path" do
        @q.slug = "changed"
        @q.save
        @p.reload.path.should == "/"
        @q.reload.path.should == "/changed"
        @r.reload.path.should == "/changed/#{@r.slug}"
        @s.reload.path.should == "/changed/#{@s.slug}"
        @t.reload.path.should == "/changed/#{@s.slug}/#{@t.slug}"
      end

      should "have direct access to ancestors at any depth" do
        @q.ancestor(0).should == @p
        @r.ancestor(0).should == @p
        @r.ancestor(1).should == @q
        @s.ancestor(1).should == @q
        @t.ancestor(1).should == @q
        @t.ancestor(2).should == @s
        @t.ancestor(-1).should == @s
        @t.ancestor(-2).should == @q
      end

      should "test for ancestry" do
        @t.ancestor?(@s).should be_true
        @t.ancestor?(@q).should be_true
        @t.ancestor?(@p).should be_true
        @q.ancestor?(@t).should be_false
      end

      should "know if it's in the current path" do
        @t.active?(@s).should be_true
        @t.active?(@t).should be_true
        @t.active?(@q).should be_true
        @t.active?(@p).should be_true
        @q.active?(@t).should be_false
      end

      should "provide a list of pages at any depth" do
        @t.at_depth(2).should == [@r, @s]
        @p.at_depth(1).should == [@q]
        lambda { @p.at_depth(2) }.must_raise(ArgumentError)
      end
    end

    context "page pieces" do
      setup do
        Page.box :things
        Piece.box :things
        @parent = Page.create
        @piece = Piece.new
        @child = Page.new
        @parent.things << @piece
        @piece.things << @child
        @parent.save
        @piece.save
        @child.save
        @page_piece = @parent.things.first.things.first
      end

      should "report their depth according to their position in the piece tree" do
        @parent.depth.should == 0
        @parent.pieces.first.depth.should == 1
        @parent.pieces.first.pieces.first.depth.should == 2
      end

      should "know their page" do
        @page_piece.page.should == @parent
      end

      should "know their container" do
        @page_piece.container.should == @piece.things
      end

      should "know their box" do
        @page_piece.box.should == @piece.things
      end

      should "know their parent" do
        @page_piece.parent.should == @piece
      end

      should "know their owner" do
        @page_piece.owner.should == @piece
      end
    end
  end
end
