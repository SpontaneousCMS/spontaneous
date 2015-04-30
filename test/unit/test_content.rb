# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Content" do
  before do
    @site = setup_site
    class C < ::Piece; end
    class P < ::Page; end

    C.box :things
    P.box :things
    P.box :box1
    P.box :box2
  end

  after do
    Object.send(:remove_const, :C) rescue nil
    Object.send(:remove_const, :P) rescue nil
    teardown_site
  end

  describe "Content instances" do
    it "evaluate instance code" do
      @instance = C.create({
        :instance_code => "def monkey; 'magic'; end"
      })
      @instance.monkey.must_equal 'magic'
      id = @instance.id
      @instance = ::Content[id]
      @instance.monkey.must_equal 'magic'
    end
  end
  describe "pieces" do
    before do
      @instance = C.new
    end

    after do
      ::Content.delete rescue nil
    end

    it "be initialised empty" do
      @instance.contents.to_a.must_equal []
    end

    it "provide a #target method poiting to itself" do
      @instance.target.must_equal @instance
    end

    it "accept addition of child content" do
      e = C.new
      @instance.things << e
      @instance.save.reload
      @instance.contents.length.must_equal 1
      @instance.things.contents.length.must_equal 1
      @instance.contents.first.must_equal e
      @instance.contents.first.container.must_equal @instance.things
      @instance.contents.first.owner.must_equal @instance
      @instance.contents.first.parent.must_equal @instance
      e.visibility_path.must_equal "#{@instance.id}"
      @instance.contents.first.visibility_path.must_equal "#{@instance.id}"
    end

    it "accept addition of multiple children" do
      e = C.new
      f = C.new
      @instance.things << e
      @instance.things << f
      @instance.save.reload
      @instance.contents.length.must_equal 2
      @instance.things.contents.length.must_equal 2
      @instance.contents.first.must_equal e
      @instance.things.contents.first.must_equal e
      @instance.contents.last.must_equal f
      @instance.things.contents.last.must_equal f
      @instance.contents.first.container.must_equal @instance.things
      @instance.contents.last.container.must_equal @instance.things
      @instance.contents.first.parent.must_equal @instance
      @instance.contents.last.parent.must_equal @instance
      @instance.contents.first.owner.must_equal @instance
      @instance.contents.last.owner.must_equal @instance
      @instance.contents.first.visibility_path.must_equal "#{@instance.id}"
      @instance.contents.last.visibility_path.must_equal "#{@instance.id}"
    end

    it "allow for a deep hierarchy" do
      e = C.new
      f = C.new
      @instance.things << e
      e.things << f
      @instance.contents.length.must_equal 1
      @instance.contents.first.must_equal e
      e.owner.id.must_equal @instance.id
      e.parent.id.must_equal @instance.id
      e.container.must_equal @instance.things
      e.visibility_path.must_equal "#{@instance.id}"

      f.owner.id.must_equal e.id
      f.parent.id.must_equal e.id
      f.container.must_equal e.things
      f.visibility_path.must_equal "#{@instance.id}.#{e.id}"
    end

    it "persist hierarchy" do
      e = C.new
      f = C.new
      e.things << f
      @instance.things << e
      @instance.save
      e.save
      f.save

      i = C[@instance.id]
      e = C[e.id]
      f = C[f.id]

      i.contents.length.must_equal 1
      i.contents.first.must_equal e

      e.container.must_equal i.things
      e.owner.must_equal i
      e.parent.must_equal i
      f.container.must_equal e.things
      f.parent.must_equal e
      f.owner.must_equal e
      e.entry.must_equal i.contents.first
      f.entry.must_equal e.contents.first
      e.contents.first.must_equal f
    end

    it "have a list of child nodes" do
      e = C.new
      f = C.new
      e.things << f
      @instance.things << e
      @instance.save
      e.save
      f.save

      i = C[@instance.id]
      e = C[e.id]
      f = C[f.id]
      i.contents.to_a.must_equal [e]
      e.contents.to_a.must_equal [f]
    end

    it "provide a list of non-page contents" do
      p = P.new

      c1 = C.new
      c2 = C.new
      c3 = C.new
      p1 = P.new
      p2 = P.new
      p3 = P.new

      p.box1 << c1
      p.box1 << c2
      p.box1 << p1

      p.box2 << p3
      p.box2 << c3

      [p, c1, c2, c3, p1, p2, p3].each { |c| c.save; c.reload }

      p = P[p.id]

      p.pieces.must_equal [c1, c2, c3]
    end


    it "allow for testing of position" do
      e = C.new
      f = C.new
      g = C.new
      @instance.things << e
      @instance.things << f
      @instance.things << g
      assert e.first?
      refute f.first?
      refute g.first?
      refute e.last?
      refute f.last?
      assert g.last?
    end

    it "know their next neighbour" do
      e = C.new
      f = C.new
      g = C.new
      @instance.things << e
      @instance.things << f
      @instance.things << g
      e.next.must_equal f
      f.next.must_equal g
      g.next.must_be_nil
    end

    it "know their previous neighbour" do
      e = C.new
      f = C.new
      g = C.new
      @instance.things << e
      @instance.things << f
      @instance.things << g
      e.previous.must_be_nil
      f.previous.must_equal e
      g.previous.must_equal f
      g.prev.must_equal f
    end

    it "record the depth of the nodes" do
      a = C.new
      b = C.new
      c = C.new

      a.depth.must_equal 0
      b.depth.must_equal 0
      c.depth.must_equal 0

      a.things << b
      b.things << c

      b.depth.must_equal 1
      c.depth.must_equal 2
    end


  end
  describe "Deletion" do
    before do
      C.delete
      @a = C.new(:label => 'a')
      @b = C.new(:label => 'b')
      @c = C.new(:label => 'c')
      @d = C.new(:label => 'd')
      @a.things << @b
      @a.things << @d
      @b.things << @c
      @a.save
      @b.save
      @c.save
      @d.save
      @a = C[@a.id]
      @b = C[@b.id]
      @c = C[@c.id]
      @d = C[@d.id]
      C.count.must_equal 4
      @ids = [@a, @b, @c, @d].map {|c| c.id }
    end
    it "recurse all the way" do
      @a.destroy
      C.count.must_equal 0
    end

    it "recurse" do
      @b.destroy
      C.count.must_equal 2
      @a.reload
      @a.contents.length.must_equal 1
      @a.contents.first.must_equal @d.reload
      C.all.map { |c| c.id }.sort.must_equal [@a, @d].map { |c| c.id }.sort
    end

    it "work through pieces" do
      @a.things.length.must_equal 2
      @a.things.first.destroy
      C.count.must_equal 2
      @a.things.length.must_equal 1
    end
  end

  describe "Moving" do
    before do
      C.delete
      @r = P.new(:label => 'r')
      @a = C.new(:label => 'a')
      @b = C.new(:label => 'b')
      @c = C.new(:label => 'c')
      @d = C.new(:label => 'd')
      @r.things << @a
      @r.things << @c
      @a.things << @b
      @c.things << @d
      [@r, @a, @b, @c, @d].each { |c| c.save; c.reload }
    end

    after do
      C.delete
    end

    it "default to adding at the end" do
      @b.parent.must_equal @a
      @r.things.adopt(@b)
      @b.reload
      @r.reload
      @b.parent.must_equal @r
      @b.container.must_equal @r.things
      @b.depth.must_equal 1
      @a.reload
      @a.things.count.must_equal 0
      @r.reload
      @r.things.last.must_equal @b
    end

    it "allow for adding in any position" do
      @b.parent.must_equal @a
      @r.things.adopt(@b, 1)
      @b.reload
      @r.reload
      @b.parent.must_equal @r
      @b.container.must_equal @r.things
      @b.depth.must_equal 1
      @a.reload
      @a.things.count.must_equal 0
      @r.reload
      @r.things[1].must_equal @b
      @r.things.adopt(@d, 0)
      @d.reload
      @r.reload
      @r.things[0].must_equal @d
    end

    it "re-set the visibility path" do
      @r.things.adopt(@b)
      @b.reload
      @b.visibility_path.must_equal @r.id.to_s
    end

    it "updates the item's depth" do
      @r.things.adopt(@b)
      @b.reload
      @b.depth.must_equal 1
    end

    it "ensure that children have their visibility paths updated" do
      paths = []
      root = @b
      3.times do |n|
        c = C.new(:label => "child-#{n}")
        root.things << c
        root.save
        c.save
        paths << c
        root = c
      end
      original_root_visibility_path = @b.visibility_path
      new_visibility_paths = paths.map(&:visibility_path).map { |vp| vp.gsub(original_root_visibility_path, @r.id.to_s) }
      @r.things.adopt(@b)
      paths.each(&:reload).map(&:visibility_path).must_equal new_visibility_paths
    end

    it "ensures that child pages have their ancestor paths updated" do
      pages = []
      page = P.new(label: 'new-root')
      @b.things << page
      page.save
      root = page
      classes = [P, C]
      use_class, next_class = classes
      5.times do |n|
        c = use_class.new(:label => "child-#{n}")
        root.things << c
        c.save
        pages << c if use_class == P
        root = c
        use_class, next_class = next_class, use_class
      end
      page = pages.first
      original_root_ancestor_path = page.ancestor_path_ids
      new_ancestor_paths = pages.map(&:ancestor_path_ids).map { |ap|
        ap.gsub(original_root_ancestor_path, @r.id.to_s)
      }
      @r.things.adopt(page)
      pages.each(&:reload).map(&:ancestor_path_ids).must_equal new_ancestor_paths
      page.parent_id.must_equal @r.id
    end

    it "ensures that child pages have their depths updated" do
      pages = []
      page = P.new(label: 'new-root')
      @b.things << page
      page.save
      root = page
      classes = [P, C]
      use_class, next_class = classes
      5.times do |n|
        c = use_class.new(:label => "child-#{n}")
        root.things << c
        c.save
        pages << c if use_class == P
        root = c
        use_class, next_class = next_class, use_class
      end
      page = pages.first
      original_depths = pages.map(&:depth)
      @r.things.adopt(page)
      new_depths = pages.map { |p| p.reload.depth }
      new_depths.must_equal original_depths.map { |d| d - 1 }
    end
  end

  describe "filtering" do
    before do
      @instances = [P.create, C.create, P.create, C.create]
    end

    after do
      C.delete
      P.delete
    end

    it "provides a to_proc method that makes filtering by class easy" do
      @instances.select(&C).map(&:class).must_equal [C, C]
    end

    it "can filter pagepieces that point to an object of the given type" do
      pps = @instances.map { |i| Spontaneous::PagePiece.new(nil, i, nil)}
      pps.select(&P).map { |i| i.to_page.class }.must_equal [P, P]
    end

    it "can filter content instances out a list POROs" do
      pps = [Object.new, Object.new, @instances.first]
      pps.select(&P).map { |i| i.to_page.class }.must_equal [P]
    end
  end
end
