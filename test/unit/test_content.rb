require 'test_helper'


class ContentTest < Test::Unit::TestCase
  include Spontaneous
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

    should "be initialised empty" do
      @instance.entries.should == []
    end

    should "accept addition of child content" do
      e = Content.new
      @instance << e
      @instance.entries.length.should == 1
      @instance.entries.first.should == e
      @instance.entries.first.container.should == @instance
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
    end

    should "allow for a deep hierarchy" do
      e = Content.new
      f = Content.new
      @instance << e
      e << f
      @instance.entries.length.should == 1
      @instance.entries.first.should == e
      e.container.should == @instance
      f.container.id.should == e.id
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
      class ::Parent < Content
        allow :Allowed1
        allow Allowed2, :styles => [:ringo, :george]
        allow 'Allowed3'
      end
    end

    teardown do
      [:Parent, :Allowed1, :Allowed2, :Allowed3].each { |k| Object.send(:remove_const, k) } rescue nil
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
  end
end
