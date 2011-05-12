# encoding: UTF-8

require 'test_helper'


class ContentTest < MiniTest::Spec
  context "Content instances" do
    should "evaluate instance code" do
      @instance = Content.create({
        :instance_code => "def monkey; 'magic'; end"
      })
      @instance.monkey.should == 'magic'
      id = @instance.id
      @instance = Content[id]
      @instance.monkey.should == 'magic'
    end
  end
  context "pieces" do
    setup do
      @instance = Content.new
    end

    teardown do
      Content.delete
    end
    should "be initialised empty" do
      @instance.pieces.should == []
    end

    should "accept addition of child content" do
      e = Content.new
      @instance << e
      @instance.pieces.length.should == 1
      @instance.pieces.first.should == e
      @instance.pieces.first.container.should == @instance
      e.content_path.should == "#{@instance.id}"
      @instance.pieces.first.content_path.should == "#{@instance.id}"
    end

    should "accept addition of multiple children" do
      e = Content.new
      f = Content.new
      @instance << e
      @instance << f
      @instance.pieces.length.should == 2
      @instance.pieces.first.should == e
      @instance.pieces.last.should == f
      @instance.pieces.first.container.should == @instance
      @instance.pieces.last.container.should == @instance
      @instance.pieces.first.content_path.should == "#{@instance.id}"
      @instance.pieces.last.content_path.should == "#{@instance.id}"
    end

    should "allow for a deep hierarchy" do
      e = Content.new
      f = Content.new
      @instance << e
      e << f
      @instance.pieces.length.should == 1
      @instance.pieces.first.should == e
      e.container.should == @instance
      e.content_path.should == "#{@instance.id}"
      f.container.id.should == e.id
      f.content_path.should == "#{@instance.id}.#{e.id}"
    end

    should "persist hierarchy" do
      e = Content.new
      f = Content.new
      e << f
      @instance << e
      @instance.save
      e.save
      f.save

      i = Content[@instance.id]
      e = Content[e.id]
      f = Content[f.id]

      i.pieces.length.should == 1
      i.pieces.first.should == e

      e.container.should == i
      f.container.should == e
      e.entry.should == i.pieces.first
      f.entry.should == e.pieces.first
      e.pieces.first.should == f
    end

    should "have a list of child nodes" do
      e = Content.new
      f = Content.new
      e << f
      @instance << e
      @instance.save
      e.save
      f.save

      i = Content[@instance.id]
      e = Content[e.id]
      f = Content[f.id]
      i.pieces.should == [e]
      e.pieces.should == [f]
    end

    should "record the depth of the nodes" do
      a = Content.new
      b = Content.new
      c = Content.new

      a.depth.should == 0
      b.depth.should == 0
      c.depth.should == 0

      a << b
      b << c

      b.depth.should == 1
      c.depth.should == 2
    end


  end
  context "Deletion" do
    setup do
      Content.delete
      @a = Content.new(:label => 'a')
      @b = Content.new(:label => 'b')
      @c = Content.new(:label => 'c')
      @d = Content.new(:label => 'd')
      @a << @b
      @a << @d
      @b << @c
      @a.save
      @b.save
      @c.save
      @d.save
      @a = Content[@a.id]
      @b = Content[@b.id]
      @c = Content[@c.id]
      @d = Content[@d.id]
      Content.count.should == 4
      @ids = [@a, @b, @c, @d].map {|c| c.id }
    end
    should "recurse all the way" do
      @a.destroy
      Content.count.should == 0
    end

    should "recurse" do
      @b.destroy
      Content.count.should == 2
      @a.reload
      @a.pieces.length.should == 1
      @a.pieces.first.should == @d.reload
      Content.all.map { |c| c.id }.should == [@a, @d].map { |c| c.id }
    end

    ## doesn't work due to
    should "work through pieces" do
      @a.pieces.first.destroy
      Content.count.should == 2
      @a.pieces.length.should == 1
    end
  end


  context "identity map" do
    setup do
      Spontaneous.database = DB
      Content.delete
      Content.delete_all_revisions!
      class ::IdentitySubclass < Content; end
      @c1 = Content.create
      @c2 = Content.create
      @i1 = IdentitySubclass.create
      @i2 = IdentitySubclass.create
    end
    teardown do
      Object.send(:remove_const, :IdentitySubclass)
      Content.delete
      Content.delete_all_revisions!
    end
    should "work for Content" do
      Content.with_identity_map do
        Content[@c1.id].object_id.should == Content[@c1.id].object_id
      end
    end

    should "work for subclasses" do
      Content.with_identity_map do
        IdentitySubclass[@i1.id].object_id.should == IdentitySubclass[@i1.id].object_id
      end
    end

    should "return different objects for different revisions" do
      revision = 2
      a = b = nil
      Content.publish(revision)
      Content.with_identity_map do
        a = Content[@c1.id]
        Content.with_revision(revision) do
          b = Content[@c1.id]
        end
        a.object_id.should_not == b.object_id
      end
    end
  end
end
