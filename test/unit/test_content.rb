# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ContentTest < MiniTest::Spec
  context "Content:" do
    setup do
      @site = setup_site
      # class Piece < Spontaneous::Piece; end
      # class Page < Spontaneous::Page; end
      class C < ::Piece; end
      class P < ::Page; end
      C.box :things
      P.box :box1
      P.box :box2
    end

    teardown do
      ContentTest.send(:remove_const, :C) rescue nil
      ContentTest.send(:remove_const, :P) rescue nil
      teardown_site
    end

    context "Content instances" do
      should "evaluate instance code" do
        @instance = C.create({
          :instance_code => "def monkey; 'magic'; end"
        })
        @instance.monkey.should == 'magic'
        id = @instance.id
        @instance = ::Content[id]
        @instance.monkey.should == 'magic'
      end
    end
    context "pieces" do
      setup do
        @instance = C.new
      end

      teardown do
        ::Content.delete rescue nil
      end

      should "be initialised empty" do
        @instance.contents.should == []
      end

      should "provide a #target method poiting to itself" do
        @instance.target.should == @instance
      end

      should "accept addition of child content" do
        e = C.new
        @instance.things << e
        @instance.contents.length.should == 1
        @instance.things.contents.length.should == 1
        @instance.contents.first.should == e
        @instance.contents.first.container.should == @instance.things
        @instance.contents.first.owner.should == @instance
        @instance.contents.first.parent.should == @instance
        e.visibility_path.should == "#{@instance.id}"
        @instance.contents.first.visibility_path.should == "#{@instance.id}"
      end

      should "accept addition of multiple children" do
        e = C.new
        f = C.new
        @instance.things << e
        @instance.things << f
        @instance.contents.length.should == 2
        @instance.things.contents.length.should == 2
        @instance.contents.first.should == e
        @instance.things.contents.first.should == e
        @instance.contents.last.should == f
        @instance.things.contents.last.should == f
        @instance.contents.first.container.should == @instance.things
        @instance.contents.last.container.should == @instance.things
        @instance.contents.first.parent.should == @instance
        @instance.contents.last.parent.should == @instance
        @instance.contents.first.owner.should == @instance
        @instance.contents.last.owner.should == @instance
        @instance.contents.first.visibility_path.should == "#{@instance.id}"
        @instance.contents.last.visibility_path.should == "#{@instance.id}"
      end

      should "allow for a deep hierarchy" do
        e = C.new
        f = C.new
        @instance.things << e
        e.things << f
        @instance.contents.length.should == 1
        @instance.contents.first.should == e
        e.owner.id.should == @instance.id
        e.parent.id.should == @instance.id
        e.container.should == @instance.things
        e.visibility_path.should == "#{@instance.id}"

        f.owner.id.should == e.id
        f.parent.id.should == e.id
        f.container.should == e.things
        f.visibility_path.should == "#{@instance.id}.#{e.id}"
      end

      should "persist hierarchy" do
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

        i.contents.length.should == 1
        i.contents.first.should == e

        e.container.should == i.things
        e.owner.should == i
        e.parent.should == i
        f.container.should == e.things
        f.parent.should == e
        f.owner.should == e
        e.entry.should == i.contents.first
        f.entry.should == e.contents.first
        e.contents.first.should == f
      end

      should "have a list of child nodes" do
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
        i.contents.should == [e]
        e.contents.should == [f]
      end

      should "provide a list of non-page contents" do
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

        p.pieces.should == [c1, c2, c3]
      end


      should "allow for testing of position" do
        e = C.new
        f = C.new
        g = C.new
        @instance.things << e
        @instance.things << f
        @instance.things << g
        e.first?.should be_true
        f.first?.should be_false
        g.first?.should be_false
        e.last?.should be_false
        f.last?.should be_false
        g.last?.should be_true
      end

      should "know their next neighbour" do
        e = C.new
        f = C.new
        g = C.new
        @instance.things << e
        @instance.things << f
        @instance.things << g
        e.next.should == f
        f.next.should == g
        g.next.should be_nil
      end

      should "know their previous neighbour" do
        e = C.new
        f = C.new
        g = C.new
        @instance.things << e
        @instance.things << f
        @instance.things << g
        e.previous.should be_nil
        f.previous.should == e
        g.previous.should == f
        g.prev.should == f
      end

      should "record the depth of the nodes" do
        a = C.new
        b = C.new
        c = C.new

        a.depth.should == 0
        b.depth.should == 0
        c.depth.should == 0

        a.things << b
        b.things << c

        b.depth.should == 1
        c.depth.should == 2
      end


    end
    context "Deletion" do
      setup do
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
        C.count.should == 4
        @ids = [@a, @b, @c, @d].map {|c| c.id }
      end
      should "recurse all the way" do
        @a.destroy
        C.count.should == 0
      end

      should "recurse" do
        @b.destroy
        C.count.should == 2
        @a.reload
        @a.contents.length.should == 1
        @a.contents.first.should == @d.reload
        C.all.map { |c| c.id }.sort.should == [@a, @d].map { |c| c.id }.sort
      end

      should "work through pieces" do
        @a.things.length.should == 2
        @a.things.first.destroy
        C.count.should == 2
        @a.things.length.should == 1
      end
    end

    context "Moving" do
      setup do
        C.delete
        @r = C.new(:label => 'r')
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

      teardown do
        C.delete
      end

      should "default to adding at the end" do
        @b.parent.should == @a
        @r.things.adopt(@b)
        @b.reload
        @r.reload
        @b.parent.should == @r
        @b.container.should == @r.things
        @b.depth.should == 1
        @a.reload
        @a.things.count.should == 0
        @r.reload
        @r.things.last.should == @b
      end

      should "allow for adding in any position" do
        @b.parent.should == @a
        @r.things.adopt(@b, 1)
        @b.reload
        @r.reload
        @b.parent.should == @r
        @b.container.should == @r.things
        @b.depth.should == 1
        @a.reload
        @a.things.count.should == 0
        @r.reload
        @r.things[1].should == @b
        @r.things.adopt(@d, 0)
        @d.reload
        @r.reload
        @r.things[0].should == @d
      end

      should "re-set the visibility path" do
        @r.things.adopt(@b)
        @b.reload
        @b.visibility_path.should == @r.id.to_s
      end

      should "ensure that child pages have their visibility paths updated" do
        flunk "Implement this"
      end
    end


    # context "identity map" do
    #   setup do

    #     ::Content.delete
    #     ::Content.delete_all_revisions!
    #     class ::IdentitySubclass < C; end
    #     @c1 = C.create
    #     @c2 = C.create
    #     @i1 = IdentitySubclass.create
    #     @i2 = IdentitySubclass.create
    #   end
    #   teardown do
    #     Object.send(:remove_const, :IdentitySubclass) rescue nil
    #     # Content.delete
    #     # Content.delete_all_revisions!
    #   end
    #   should "work for Content" do
    #     Content.with_identity_map do
    #       Content[@c1.id].object_id.should == Content[@c1.id].object_id
    #     end
    #   end

    #   should "work for subclasses" do
    #     Content.with_identity_map do
    #       IdentitySubclass[@i1.id].object_id.should == IdentitySubclass[@i1.id].object_id
    #     end
    #   end

    #   should "return different objects for different revisions" do
    #     revision = 2
    #     a = b = nil
    #     Content.publish(revision)
    #     Content.with_identity_map do
    #       a = Content[@c1.id]
    #       Content.with_revision(revision) do
    #         b = Content[@c1.id]
    #       end
    #       a.object_id.should_not == b.object_id
    #     end
    #   end
    # end
  end
end
