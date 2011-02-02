# encoding: UTF-8

require 'test_helper'


class ContentTest < Test::Unit::TestCase
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
  context "Entries" do
    setup do
      @instance = Content.new
    end

    teardown do
      Content.delete
    end
    should "be initialised empty" do
      @instance.entries.should == []
    end

    should "accept addition of child content" do
      e = Content.new
      @instance << e
      @instance.entries.length.should == 1
      @instance.entries.first.should == e
      @instance.entries.first.container.should == @instance
      e.content_path.should == "#{@instance.id}"
      @instance.entries.first.content_path.should == "#{@instance.id}"
    end

    should "accept addition of multiple children" do
      e = Content.new
      f = Content.new
      @instance << e
      @instance << f
      @instance.entries.length.should == 2
      @instance.entries.first.should == e
      @instance.entries.last.should == f
      @instance.entries.first.container.should == @instance
      @instance.entries.last.container.should == @instance
      @instance.entries.first.content_path.should == "#{@instance.id}"
      @instance.entries.last.content_path.should == "#{@instance.id}"
    end

    should "allow for a deep hierarchy" do
      e = Content.new
      f = Content.new
      @instance << e
      e << f
      @instance.entries.length.should == 1
      @instance.entries.first.should == e
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

      i.entries.length.should == 1
      i.entries.first.should == e

      e.container.should == i
      f.container.should == e
      e.entry.should == i.entries.first
      f.entry.should == e.entries.first
      e.entries.first.should == f
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
      i.nodes.should == [e]
      e.nodes.should == [f]
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

    should "add shortcut access methods based on facet.name" do
      a = Content.new
      b = Content.new
      c = Content.new

      b.label = "fishes"
      c.label = "cows"

      a << b
      b << c

      a.fishes.should == b
      b.cows.should == c
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
      @a.entries.length.should == 1
      @a.entries.first.should == @d.reload
      Content.all.map { |c| c.id }.should == [@a, @d].map { |c| c.id }
    end

    ## doesn't work due to
    should "work through entries" do
      @a.entries.first.destroy
      Content.count.should == 2
      @a.entries.length.should == 1
    end
  end


  context "Content" do
    setup do
      class ::Allowed1 < Content
        inline_style :frank
        inline_style :freddy
      end
      class ::Allowed2 < Content
        inline_style :john
        inline_style :paul
        inline_style :ringo
        inline_style :george
      end
      class ::Allowed3 < Content
        inline_style :arthur
        inline_style :lancelot
      end
      class ::Allowed4 < Content; end
      class ::Parent < Content
        allow :Allowed1
        allow Allowed2, :styles => [:ringo, :george]
        allow 'Allowed3'
      end

      class ::ChildClass < ::Parent
        slot :parents, :type => :Parent
      end
    end

    teardown do
      [:Parent, :Allowed1, :Allowed2, :Allowed3, :Allowed4, :ChildClass].each { |k| Object.send(:remove_const, k) } rescue nil
    end
    should "have a list of allowed types" do
      Parent.allowed.length.should == 3
    end

    should "have understood the type parameter" do
      Parent.allowed[0].instance_class.should == Allowed1
      Parent.allowed[1].instance_class.should == Allowed2
      Parent.allowed[2].instance_class.should == Allowed3
    end

    should "raise an error when given an invalid type name" do
      lambda { Parent.allow :WhatTheHellIsThis }.should raise_error(UnknownTypeException)
    end

    should "allow all styles by default" do
      Parent.allowed[2].styles.should == Allowed3.inline_styles
    end

    should "have a list of allowable styles" do
      Parent.allowed[1].styles.length.should == 2
      Parent.allowed[1].styles.map { |s| s.name }.should == [:ringo, :george]
    end

    should "raise an error if we try to use an unknown style" do
      lambda { Parent.allow :Allowed3, :styles => [:merlin, :arthur]  }.should raise_error(Spontaneous::UnknownStyleException)
    end

    should "use a configured style when adding a defined allowed type" do
      a = Parent.new
      b = Allowed2.new
      a << b
      a.entries.first.style.should == Allowed2.inline_styles[:ringo]
    end

    should "know what the available styles are for an entry" do
      a = Parent.new
      b = Allowed2.new
      c = Allowed3.new
      a << b
      a << c
      a.available_styles(b).map { |s| s.name }.should == [:ringo, :george]
      a.available_styles(c).map { |s| s.name }.should == [:arthur, :lancelot]
    end

    should "inherit allowed types from superclass" do
      ChildClass.allowed.should == Parent.allowed
    end

    should "include a subtype's allowed list as well as the supertype's" do
      ChildClass.allow :Allowed4
      ChildClass.allowed.map {|a| a.instance_class }.should == (Parent.allowed.map {|a| a.instance_class } + [Allowed4])
    end

    should "propagate allowed types to slots" do
      instance = ChildClass.new
      instance.parents.allowed_types.should == Parent.allowed_types
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
