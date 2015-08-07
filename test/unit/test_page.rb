# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Page" do
  before do
    @site = setup_site
    Content.delete
    class ::Page
      field :title, :string
      box :sub
    end
  end

  after do
    Object.send(:remove_const, :Page)
    Object.send(:remove_const, :Piece)
    teardown_site
  end

  describe "Root page" do
    it "be created by first page insert" do
      p = Page.create
      assert p.root?
      p.path.must_equal "/"
      p.slug.must_equal ""
      p.parent.must_be_nil
    end

    it "be a singleton" do
      p = Page.create
      assert p.root?
      q = Page.create(slug: 'something')
      refute q.root?
    end
  end

  describe "private roots" do
    before do
      @root = Page.create
      assert @root.root?
      class ::ErrorPage < Page; end
      ErrorPage.box :pages
    end

    after do
      Object.send :remove_const, :ErrorPage rescue nil
    end

    it "is given a path starting with '#'" do
      root = Page.create slug: "error"
      root.path.must_equal "#error"
    end

    it "re-calculates its path using '#'" do
      root = ErrorPage.create slug: "error"
      page = Page.new slug: "404"
      root.pages << page
      root.save
      page.save
      root.path.must_equal "#error"
      page.reload.path.must_equal "#error/404"
      root.slug = "changed"
      root.save
      root.path.must_equal "#changed"
      page.reload.path.must_equal "#changed/404"
    end

    it "has paths that start with '#'" do
      root = ErrorPage.create slug: "error"
      page = Page.new slug: "404"
      root.pages << page
      root.save
      page.path.must_equal "#error/404"
    end

    it "has a depth of 0" do
      root = ErrorPage.create slug: "error"
      root.depth.must_equal 0
    end

    it "raises an error if the alternate root doesn't have a slug" do
      lambda { Page.create slug: "" }.must_raise Spontaneous::AnonymousRootException
    end

    it "allows the creation of invisible roots without a visible root" do
      Page.root.destroy
      Page.root.must_equal nil
      root = ErrorPage.create_root "error"
      Page.root.must_equal nil
      @site["#error"].must_equal root.reload
    end

    it "gives children of invisible roots the correct root page" do
      root = ErrorPage.create_root "error"
      child = ::Page.new
      root.pages << child
      root.save
      child.save
      child.tree_root.must_equal root
    end

    it "allows you to test if the page is an invisible root" do
      @root.is_private_root?.must_equal false
      child = ::Page.new
      @root.sub << child
      child.save
      child.is_private_root?.must_equal false
      invisible_root = ErrorPage.create_root "error"
      invisible_root.is_private_root?.must_equal true
      child = ::Page.new
      invisible_root.pages << child
      invisible_root.save
      child.save
      child.is_private_root?.must_equal false
    end

    it "allows you to test if a page belongs to an invisible sub-tree" do
      @root.in_private_tree?.must_equal false
      child = ::Page.new
      @root.sub << child
      child.save
      child.in_private_tree?.must_equal false

      invisible_root = ErrorPage.create_root "error"
      invisible_root.in_private_tree?.must_equal true
      child = ::Page.new
      invisible_root.pages << child
      invisible_root.save
      child.save
      child.in_private_tree?.must_equal true
    end
  end

  describe "Slugs" do
    before do
      Page.box :subs
      @root = Page.create
      assert @root.root?
    end
    after do
      Content.send :remove_const, :DynamicDefault rescue nil
    end

    it "be generated if missing" do
      p = @root.subs << Page.new
      p.slug.wont_equal ""
      p.save
      p.reload.slug.wont_equal ""
    end

    it 'can be given a type specific root' do
      class Page
        def default_slug_root
          'fishies'
        end
      end
      p = @root.subs << Page.new
      p.save
      p.slug.must_match /^fishies/
      p.has_generated_slug?.must_equal true
    end

    it "be made URL safe" do
      p = @root.subs << Page.new
      p.slug = " something's illegal and ugly!!"
      p.slug.must_equal "somethings-illegal-and-ugly"
      p.save
      p.reload.slug.must_equal "somethings-illegal-and-ugly"
    end

    it "be set from title if using generated slug" do
      r = @root.subs << Page.new
      slug = Page.generate_default_slug
      Page.stubs(:generate_default_slug).returns(slug)
      o = Page.new
      p = Page.new
      r.sub << o
      o.slug.must_equal slug
      o = Page[o.id]
      o.slug.must_equal slug
      o.sub << p
      o.save
      o = Page[o.id]
      o.slug.must_equal slug
      o.title = "New Title"
      o.save
      o.reload
      o.slug.must_equal "new-title"
      o.title = "Another Title"
      o.save
      o.reload
      o.slug.must_equal "new-title"
    end

    it "isn't set from a dynamic default value" do
      r = @root.subs << Page.new
      slug = Page.generate_default_slug
      Page.stubs(:generate_default_slug).returns(slug)
      class ::DynamicDefault < Page
        field :title, default: proc { |page| 'Really new thing' }
      end
      o = DynamicDefault.new
      r.sub << o
      o.slug.wont_equal 'really-new-thing'
      o.slug.must_equal slug
      o.title.value.must_equal 'Really new thing'
    end

    it "doesn't set a conflicting url on creation" do
      r = @root.subs << Page.new
      o = Page.new(title: "New Page")
      r.sub << o
      o.save

      p = Page.new(title: "New Page")
      r.sub << p
      p.save
      slug_o = o.slug
      slug_p = p.slug
      o.slug.wont_equal p.slug
    end

    it "fixes conflicting slugs automatically" do
      r = @root.subs << Page.new(slug: 'section')
      o = Page.new(title: "New Page", slug: "my-slug")
      r.sub << o
      o.save

      page = Page.new(title: "New Page")
      r.sub << page
      page.save
      page.slug = "my-slug"
      page.save
      o.slug.wont_equal page.slug
      page.path.must_equal "/section/my-slug-01"
    end

    it "fixes conflicting slugs created from titles automatically" do
      r = @root.subs << Page.new(slug: 'section')
      o = Page.new(title: "New Page", slug: "my-slug")
      r.sub << o
      o.save

      p = Page.new
      r.sub << p
      p.save
      p.title = "My Slug"
      p.save
      p.slug.must_equal "my-slug-01"
      o.slug.wont_equal p.slug
      p.path.must_equal "/section/my-slug-01"
    end

    it "not be longer than 64 chars" do
      o = @root.subs << Page.new
      # o = Page.create
      long_slug = (["bang"]*100)
      o.slug = long_slug.join(' ')
      o.slug.length.must_equal 64
      o.slug.must_equal long_slug.join('-')[0..63]
    end

    it "should crop titles at word boundaries" do
      # o = Page.create
      o = @root.subs << Page.new
      long_slug = (["bangor"]*100)
      expected = %w(bangor bangor bangor bangor bangor bangor bangor bangor bangor).join('-')
      o.slug = long_slug.join(' ')
      o.slug.length.must_equal expected.length
      o.slug.must_equal expected
    end

    it "should just crop a very long word to the max length" do
      # o = Page.create
      o = @root.subs << Page.new
      o.slug = "a"*100
      o.slug.length.must_equal 64
    end
  end

  describe "Pages in tree" do
    before do
      Content.delete
      @p = Page.create
      assert @p.root?
      @q = Page.new(:slug => 'q')
      @r = Page.new(:slug => 'r')
      @s = Page.new(:slug => 's')
      @t = Page.new(:slug => 't')
      @p.sub << @q
      @q.sub << @r
      @q.sub << @s
      @s.sub << @t
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

    it "knows its rootiness" do
      assert @p.is_public_root?
    end

    it "be able to find a reference to their inline entry" do
      @q.entry.class.must_equal Spontaneous::PagePiece
    end

    it "have a reference to their parent" do
      @p.parent.must_be_nil
      @q.parent.must_equal @p
      @r.parent.must_equal @q
      @s.parent.must_equal @q
      @t.parent.must_equal @s
    end
    it "have a reference to their owner" do
      @p.owner.must_be_nil
      @q.owner.must_equal @p
      @r.owner.must_equal @q
      @s.owner.must_equal @q
      @t.owner.must_equal @s
    end

    it "know their container" do
      @p.container.must_be_nil
      @q.container.must_equal @p.sub
      @r.container.must_equal @q.sub
      @s.container.must_equal @q.sub
      @t.container.must_equal @s.sub
    end

    it "know their containing box" do
      @p.box.must_be_nil
      @q.box.must_equal @p.sub
      @r.box.must_equal @q.sub
      @s.box.must_equal @q.sub
      @t.box.must_equal @s.sub
    end

    it "have a list of their children" do
      @p.children.must_equal [@q]
      @q.children.must_equal [@r, @s]
      @r.children.must_equal []
      @s.children.must_equal [@t]
      @t.children.must_equal []
    end

    it "have a reference to themselves as page" do
      @p.page.must_equal @p
      @q.page.must_equal @q
      @r.page.must_equal @r
      @s.page.must_equal @s
      @t.page.must_equal @t
    end

    it "have a reference to themselves as content_instance" do
      @p.content_instance.must_equal @p
    end

    it "keep track of their depth" do
      @p.depth.must_equal 0
      @q.depth.must_equal 1
      @r.depth.must_equal 2
      @s.depth.must_equal 2
      @t.depth.must_equal 3
    end

    it "have the correct page hierarchy" do
      Page.box :things1
      Page.box :things2
      a = @p.sub << Page.new
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
      c.parent.must_equal a
      d.parent.must_equal a
      e.parent.must_equal a
      c.content_ancestors.must_equal [a, a.things1]
      d.content_ancestors.must_equal [a, a.things2]
      e.content_ancestors.must_equal [a, a.things2]
      # the zeroth box is 'sub'
      c.page_order_string.must_equal "00001.00000"
      d.page_order_string.must_equal "00002.00000"
      e.page_order_string.must_equal "00002.00001"
    end

    it "have the correct page hierarchy for pages within pieces" do
      Page.box :things
      Piece.box :pages
      a = @p.sub << Page.new
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
      c.parent.must_equal a
      c.content_ancestors.must_equal [a, a.things, b, b.pages]
      c.page_order_string.must_equal "00001.00000.00000.00000"
      d.page_order_string.must_equal "00001.00000.00000.00001"
    end

    it "have correct paths" do
      @p.path.must_equal "/"
      @q.path.must_equal "/q"
      @r.path.must_equal "/q/r"
      @s.path.must_equal "/q/s"
      @t.path.must_equal "/q/s/t"
    end

    it "update paths when being adopted" do
      @p.sub.adopt(@s)
      @s.reload
      @t.reload
      @s.path.must_equal "/s"
      @t.path.must_equal "/s/t"
    end

    it "all have a reference to the root node" do
      @p.root.must_equal @p
      @q.root.must_equal @p
      @r.root.must_equal @p
      @s.root.must_equal @p
      @t.root.must_equal @p
    end

    it "have correct ancestor paths" do
      @p.ancestor_path.must_equal []
      @q.ancestor_path.must_equal [@p.id]
      @r.ancestor_path.must_equal [@p.id, @q.id]
      @s.ancestor_path.must_equal [@p.id, @q.id]
      @t.ancestor_path.must_equal [@p.id, @q.id, @s.id]
    end
    it "know their ancestors" do
      # must be a better way to test these arrays
      @p.ancestors.must_equal []
      @q.ancestors.must_equal [@p]
      @r.ancestors.must_equal [@p, @q]
      @s.ancestors.must_equal [@p, @q]
      @t.ancestors.must_equal [@p, @q, @s]
    end

    it "know their generation" do
      @r.generation.must_equal [@r, @s]
      @s.generation.must_equal [@r, @s]
    end

    it "know their siblings" do
      @r.siblings.must_equal [@s]
      @s.siblings.must_equal [@r]
    end

    it "always have the right path" do
      @q.slug = "changed"
      @q.save
      @p.reload.path.must_equal "/"
      @q.reload.path.must_equal "/changed"
      @r.reload.path.must_equal "/changed/#{@r.slug}"
      @s.reload.path.must_equal "/changed/#{@s.slug}"
      @t.reload.path.must_equal "/changed/#{@s.slug}/#{@t.slug}"
    end

    it "have direct access to ancestors at any depth" do
      @q.ancestor(0).must_equal @p
      @r.ancestor(0).must_equal @p
      @r.ancestor(1).must_equal @q
      @s.ancestor(1).must_equal @q
      @t.ancestor(1).must_equal @q
      @t.ancestor(2).must_equal @s
      @t.ancestor(-1).must_equal @s
      @t.ancestor(-2).must_equal @q
    end

    it "returns itself as an ancestor when given its own depth" do
      @r.ancestor(2).must_equal @r
    end

    it "test for ancestry" do
      assert @t.ancestor?(@s)
      assert @t.ancestor?(@q)
      assert @t.ancestor?(@p)
      refute @q.ancestor?(@t)
    end

    it "know if it's in the current path" do
      assert @t.active?(@s)
      assert @t.active?(@t)
      assert @t.active?(@q)
      assert @t.active?(@p)
      refute @q.active?(@t)
    end

    it "provide a list of pages at any depth" do
      @t.at_depth(2).must_equal [@r, @s]
      @p.at_depth(1).must_equal [@q]
      @q.at_depth(2).must_equal [@r, @s]
      lambda { @p.at_depth(2) }.must_raise(ArgumentError)
    end

    describe 'custom path roots' do
      before do
        Page.box :custom do
          def path_origin
            root
          end
        end
        Page.box :custom_string do
          def path_origin
            "/"
          end
        end
        Page.box :sections
        @parent = @p
        @child = Page.create(slug: 'child')
        @parent.sections << @child
        @child.path.must_equal '/child'
      end

      it "defines child paths according to the custom path root" do
        page = Page.create(slug: 'balloon')
        @child.custom << page
        page.save.reload
        page.path.must_equal '/balloon'
      end

      it "allows for string based path origins" do
        page = Page.create(slug: 'balloon')
        @child.custom_string << page
        page.save.reload
        page.path.must_equal '/balloon'
      end

      it "correctly identifies slug conflicts" do
        Page.box :fishes do
          def path_origin; ::File.join(super.path, 'fishes'); end
        end
        Page.box :mammals do
          def path_origin; ::File.join(super.path, 'mammals'); end
        end
        page = @parent.sections << Page.new(slug: 'animals')
        fish = page.fishes << Page.create(slug: 'a')
        mammal = page.mammals << Page.create(slug: 'b')
        fish.path.must_equal '/animals/fishes/a'
        mammal.path.must_equal '/animals/mammals/b'

        fish.is_conflicting_slug?('b').must_equal false

        fish.slug = 'b'
        fish.save
        fish.path.must_equal '/animals/fishes/b'
      end
    end
  end

  describe "page pieces" do
    before do
      Page.box :things
      Piece.box :things
      @parent = Page.create
      @piece = Piece.new
      @child = Page.new
      @parent.things << @piece
      @piece.things << @child
      @parent.save.reload
      @piece.save.reload
      @child.save.reload
      @page_piece = @parent.things.first.things.first
    end

    it "report their depth according to their position in the piece tree" do
      @parent.depth.must_equal 0
      @parent.contents.first.depth.must_equal 1
      @parent.contents.first.contents.first.depth.must_equal 2
    end

    it "know their page" do
      @page_piece.page.reload.must_equal @parent.reload
    end

    it "know their container" do
      @page_piece.container.must_equal @piece.things
    end

    it "know their box" do
      @page_piece.box.must_equal @piece.things
    end

    it "know their parent" do
      @page_piece.parent.reload.must_equal @piece
    end

    it "know their owner" do
      @page_piece.owner.reload.must_equal @piece
    end

    it "tests as equal to the page target" do
      @piece.reload
      assert @piece.things.first == @child, "PagePiece must == its target"
      assert @child == @piece.things.first, "Page must == a PagePiece that wraps it"
      refute @parent == @piece.things.first
    end
  end
end
