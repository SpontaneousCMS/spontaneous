# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Boxes" do

  before do
    @site = setup_site
  end

  after do
    teardown_site
  end

  describe "Box definitions" do
    before do

      class ::MyBoxClass < Box; end
      class ::MyContentClass < Piece; end
      class ::MyContentClass2 < MyContentClass; end
      MyContentClass.field :description
    end

    after do
      Object.send(:remove_const, :MyContentClass2) rescue nil
      Object.send(:remove_const, :MyContentClass) rescue nil
      Object.send(:remove_const, :MyBoxClass) rescue nil
    end

    it "start empty" do
      MyContentClass.boxes.length.must_equal 0
    end

    it "have a flag showing there are no defined boxes" do
      refute MyContentClass.has_boxes?
    end

    it "be definable with a name" do
      MyContentClass.box :images0
      MyContentClass.boxes.length.must_equal 1
      MyContentClass.boxes.first.name.must_equal :images0
      assert MyContentClass.has_boxes?
    end

    it "have a boolean test for emptiness" do
      MyContentClass.box :images0
      instance = MyContentClass.new
      assert instance.images0.empty?
      instance.images0 << MyContentClass.new
      refute instance.images0.empty?
    end

    it "always return a symbol for the name" do
      MyContentClass.box 'images0'
      MyContentClass.boxes.first.name.must_equal :images0
    end

    it "create a method of the same name" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      instance = MyContentClass.new
      instance.images1.class.superclass.must_equal Box
      instance.images2.class.superclass.must_equal MyBoxClass
    end

    it "be available by name" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      MyContentClass.boxes[:images1].must_equal MyContentClass.boxes.first
      MyContentClass.boxes[:images2].must_equal MyContentClass.boxes.last
      instance = MyContentClass.new
      instance.boxes[:images1].class.superclass.must_equal Box
      instance.boxes[:images2].class.superclass.must_equal MyBoxClass
    end

    it "accept a custom instance class" do
      MyContentClass.box :images1, :type => MyBoxClass
      MyContentClass.boxes.first.instance_class.superclass.must_equal MyBoxClass
    end

    it "accept a custom instance class as a string" do
      MyContentClass.box :images1, :type => 'MyBoxClass'
      MyContentClass.boxes.first.instance_class.superclass.must_equal MyBoxClass
    end

    it "accept a custom instance class as a symbol" do
      MyContentClass.box :images1, :type => :MyBoxClass
      MyContentClass.boxes.first.instance_class.superclass.must_equal MyBoxClass
    end

    it "Instantiate a box of the correct class" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      instance = MyContentClass.new
      instance.boxes.first.class.superclass.must_equal Box
      instance.boxes.last.class.superclass.must_equal MyBoxClass
    end

    it "give access to the prototype within the instance" do
      MyContentClass.box :images1
      instance = MyContentClass.new
      instance.boxes[:images1]._prototype.must_equal MyContentClass.boxes[:images1]
    end

    it "Use the name as the title by default" do
      MyContentClass.box :band_and_band
      MyContentClass.box :related_items
      MyContentClass.boxes.first.title.must_equal "Band & Band"
      MyContentClass.boxes.last.title.must_equal "Related Items"
    end

    it "have 'title' option" do
      MyContentClass.box :images4, :title => "Custom Title"
      MyContentClass.boxes.first.title.must_equal "Custom Title"
    end

    it "inherit boxes from superclass" do
      MyContentClass.box :images1, :type => :MyBoxClass
      MyContentClass2.box :images2
      MyContentClass2.boxes.length.must_equal 2
      instance = MyContentClass2.new
      instance.images1.class.superclass.must_equal MyBoxClass
      instance.images2.class.superclass.must_equal Box
      instance.boxes.length.must_equal 2
    end

    it "know their ordering in the container" do
      MyContentClass.box :box1
      MyContentClass.box :box2
      MyContentClass.box :box3
      MyContentClass.box_order :box3, :box2, :box1
      MyContentClass.boxes.box3.position.must_equal 0
      MyContentClass.boxes.box2.position.must_equal 1
      MyContentClass.boxes.box1.position.must_equal 2
      instance = MyContentClass.new
      instance.box3.position.must_equal 0
      instance.box2.position.must_equal 1
      instance.box1.position.must_equal 2
    end

    describe "instances" do
      it "have a connection to their owner" do
        MyContentClass.box :box1
        instance = MyContentClass.new
        instance.box1.owner.must_equal instance
        instance.box1.parent.must_equal instance
      end

      it "have a link to their container (which is their owner)" do
        MyContentClass.box :box1
        instance = MyContentClass.new
        instance.box1.container.must_equal instance
        instance.box1.container.must_equal instance
      end

      it "return their owner as content_instance" do
        MyContentClass.box :box1
        instance = MyContentClass.new
        instance.box1.content_instance.must_equal instance
      end
    end

    describe "ranges" do
      before do
        MyContentClass.box :images1
        MyContentClass.box :images2
        MyContentClass.box :images3
        MyContentClass.box :images4
        MyContentClass.box :images5
        MyContentClass2.box :images6
        @instance = MyContentClass.new
        @instance2 = MyContentClass2.new
      end
      it "allow access to groups of boxes through ranges" do
        @instance.boxes[1..-2].map { |b| b.box_name }.must_equal [:images2, :images3, :images4]
        @instance2.boxes[1..-2].map { |b| b.box_name }.must_equal [:images2, :images3, :images4, :images5]
      end

      it "allow you to pass a list of names" do
        @instance.boxes[:images1, :images4].map { |b| b.box_name }.must_equal [:images1, :images4]
        @instance2.boxes[:images1, :images6].map { |b| b.box_name }.must_equal [:images1, :images6]
      end

      it "allow a mix of names and indexes" do
        @instance.boxes[0..2, :images5].map { |b| b.box_name }.must_equal [:images1, :images2, :images3, :images5]
      end
    end

    describe "with superclasses" do
      before do
        MyContentClass.box :images6, :tag => :main

        @subclass1 = Class.new(MyContentClass) do
          box :monkeys, :tag => :main
          box :apes
        end
        @subclass2 = Class.new(@subclass1) do
          box :peanuts
        end
      end
      it "inherit boxes from its superclass" do
        @subclass2.boxes.length.must_equal 4
        @subclass2.boxes.map { |s| s.name }.must_equal [:images6, :monkeys, :apes, :peanuts]
        # @subclass2.boxes.tagged(:main).length.must_equal 2
        instance = @subclass2.new
        instance.boxes.length.must_equal 4
      end

      it "allow customisation of the box order" do
        new_order = [:peanuts, :apes, :images6, :monkeys]
        @subclass2.box_order *new_order
        @subclass2.boxes.map { |s| s.name }.must_equal new_order
      end

      it "take order of instance boxes from class defn" do
        new_order = [:peanuts, :apes, :images6, :monkeys]
        @subclass2.box_order *new_order
        instance = @subclass2.new
        instance.boxes.map { |e| e.box_name.to_sym }.must_equal new_order
      end
    end

    it "accept values for the box's fields"
    it "allow overwriting of class definitions using a block"
  end

  describe "Box classes" do
    before do
      @site.stubs(:template_root).returns(File.expand_path('../../fixtures/templates/boxes', __FILE__))
      class ::MyContentClass < ::Piece; end
      class ::MyBoxClass < Box; end
      MyBoxClass.field :title, :string
      MyBoxClass.field :description, :string
      MyContentClass.box :images, :class => :MyBoxClass, :fields => {
        :title => "Default Title",
        :description => "Default Description"
      }
      @content = MyContentClass.new
    end

    after do
      Object.send(:remove_const, :MyContentClass) rescue nil
      Object.send(:remove_const, :MyBoxClass) rescue nil
    end

    it "have fields" do
      MyBoxClass.fields.length.must_equal 2
      MyBoxClass.field :another, :string
      MyBoxClass.fields.length.must_equal 3
    end

    describe "with fields" do

      it "save their field values" do
        @content.images.title = "something"
        @content.images.description = "description here"
        @content.save
        @content.reload
        @content.images.title.value.must_equal "something"
        @content.images.description.value.must_equal "description here"
      end

      it "take initial values from box definition" do
        @content.images.title.value.must_equal "Default Title"
        @content.images.description.value.must_equal "Default Description"
      end
    end

    it "allow inline definition of fields" do
      MyContentClass.box :partners do
        field :name, :string
        field :logo, :image
        field :description, :string
      end
      instance = MyContentClass.new
      assert instance.partners.name.class < Spontaneous::Field::String
      instance.partners.name = "Howard"
      instance.partners.description = "Here is Howard"
      instance.save
      instance = Content[instance.id]
      instance.partners.name.value.must_equal "Howard"
      instance.partners.description.value.must_equal "Here is Howard"
    end

    # true?
    it "default to template in root with the same name"
  end

  describe "Box content" do
    before do
      class ::BlankContent < ::Piece; end
      class ::StyledContent < ::Piece; end

      BlankContent.style :blank1
      BlankContent.style :blank2
      BlankContent.style :blank3
      BlankContent.box :images
      BlankContent.box :words

      StyledContent.box :one do
        allow :BlankContent, :style => :blank2
      end

      StyledContent.box :two do
        allow :BlankContent, :styles => [:blank3, :blank2]
      end

      @parent = BlankContent.new
    end

    after do
      Object.send(:remove_const, :BlankContent) rescue nil
      Object.send(:remove_const, :StyledContent) rescue nil
    end

    it "be addable" do
      child1 = BlankContent.new
      child2 = BlankContent.new
      child3 = BlankContent.new
      @parent.images << child1
      @parent.words << child2
      child1.box.schema_id.must_equal @parent.images.schema_id
      child2.box.schema_id.must_equal @parent.words.schema_id
      @parent.save
      child1.images << child3
      child1.save
      @parent = Content[@parent.id]
      child1.reload; child2.reload; child3.reload
      @parent.images.contents.to_a.must_equal [child1]
      @parent.images.contents.to_a.must_equal [child1]
      @parent.words.contents.to_a.must_equal [child2]
      @parent.words.contents.to_a.must_equal [child2]
      @parent.contents.to_a.must_equal [child1, child2]
      child1.images.contents.to_a.must_equal [child3]
      child1.contents.to_a.must_equal [child3]

      @parent.images.contents.first.box.must_equal @parent.images
      @parent.words.contents.first.box.must_equal @parent.words
      @parent.contents.first.box.must_equal @parent.images
    end

    it "choose correct style" do
      styled = StyledContent.new
      child1 = BlankContent.new
      child2 = BlankContent.new
      child3 = BlankContent.new
      styled.one << child1
      styled.two << child2
      styled.save
      styled = Content.get styled.id

      styled.one.contents.first.style.name.must_equal :blank2
      styled.two.contents.first.style.name.must_equal :blank3
    end

    it "be insertable at any position" do
      BlankContent.box :box3
      BlankContent.box :box4
      instance = BlankContent.new
      count = 4
      [:images, :words, :box3, :box4].map { |name| instance.boxes[name] }.each do |box|
        count.times { |n| box << StyledContent.new(:label => n)}
      end
      instance.box4.insert(1, StyledContent.new(:label => "a"))
      instance.box4.contents.map { |e| e.label }.must_equal ["0", "a", "1", "2", "3"]
      instance.box4.insert(5, StyledContent.new(:label => "b"))
      instance.box4.contents.map { |e| e.label }.must_equal ["0", "a", "1", "2", "3", "b"]
      instance.box3.insert(2, StyledContent.new(:label => "c"))
      instance.box3.contents.map { |e| e.label }.must_equal ["0", "1", "c", "2", "3"]
    end

    it 'should be available as a list of ids' do
      BlankContent.box :box3
      instance = BlankContent.new
      contents = 3.times.map { instance.words << StyledContent.new }
      3.times.map { instance.images << StyledContent.new }
      instance.save
      contents.each(&:save)
      ids = contents.map(&:id)
      instance.words.ids.must_equal ids
    end

    it 'should be clearable' do
      instance = BlankContent.create
      box = instance.images
      count = 4
      count.times { |n| box << StyledContent.new(:label => n)}
      instance.save
      instance.images.clear!
      instance.reload.images.length.must_equal 0
    end

    it 'should be movable down' do
      instance = BlankContent.create
      box = instance.images
      entries = 3.times.map { |n| box << StyledContent.new(:label => n)}
      original_ids = entries.map(&:id)
      instance.save
      entries.first.set_position(2)
      instance.save.reload
      instance.images.ids.must_equal [original_ids[1], original_ids[2], original_ids[0]]
      instance.images.map(&:box_position).must_equal [0, 1, 2]
    end

    it 'should be movable up' do
      instance = BlankContent.create
      box = instance.images
      entries = 3.times.map { |n| box << StyledContent.new(:label => n)}
      original_ids = entries.map(&:id)
      instance.save
      entries.last.set_position(0)
      instance.save.reload
      instance.images.ids.must_equal [original_ids[2], original_ids[0], original_ids[1]]
      instance.images.map(&:box_position).must_equal [0, 1, 2]
    end

    it 'should be sample-able' do
      instance = BlankContent.create
      box = instance.images
      entries = 5.times.map { |n| box << StyledContent.new(:label => n)}
      sample = box.sample(3)
      sample.map(&:id).wont_equal entries.map(&:id)
      sample = box.contents.sample(3)
      sample.map(&:id).wont_equal entries.map(&:id)
    end

    it 'should return the single entry if sampling a box of length 1' do
      instance = BlankContent.create
      box = instance.images
      entry = instance.images << StyledContent.new(:label => 'only')
      entry.save
      instance.save
      instance.images.sample!.must_equal entry
    end

    it 'should provide a sample! method that doesn’t load the box contents' do
      instance = BlankContent.create
      box = instance.images
      entries = 10.times.map { |n| box << StyledContent.new(:label => n)}
      box.contents.expects(:load_contents).never
      sample1 = [box.sample!, box.sample!, box.sample!, box.sample!]
      sample2 = [box.sample!, box.sample!, box.sample!, box.sample!]
      sample1.wont_equal sample2
    end

    it 'supports any array methods by proxying onto the backing store' do
      instance = BlankContent.create
      box = instance.images
      entries = 4.times.map { |n| box << StyledContent.new(:label => n)}
      result = box.in_groups_of(2)
      result.length.must_equal 2
    end
  end

  describe "Allowed types" do
    before do
      class ::Allowed1 < Piece
        style :frank
        style :freddy
      end
      class ::Allowed2 < Piece
        style :john
        style :paul
        style :ringo
        style :george
      end
      class ::Allowed3 < Piece
        style :arthur
        style :lancelot
      end
      class ::Allowed4 < Piece; end

      class ::Allowed11 < ::Allowed1; end
      class ::Allowed111 < ::Allowed1; end

      class ::Parent < Box
        allow :Allowed1
        allow Allowed2, :styles => [:ringo, :george]
        allow 'Allowed3'
      end

      class ::ChildClass < ::Parent
      end

      class ::Allowable < Piece
        box :parents, :type => :Parent
      end

      class ::Mixed < Box
        allow_subclasses :Allowed1
      end

      class ::AllowedAs < Box
        allow :Allowed1, as: "Something Else"
      end
    end

    after do
      [:Parent, :Allowed1, :Allowed11, :Allowed111, :Allowed2, :Allowed3, :Allowed4, :ChildClass, :Allowable, :Mixed, :AllowedAs].each { |k| Object.send(:remove_const, k) } rescue nil
    end

    it "have a list of allowed types" do
      Parent.allowed.length.must_equal 3
    end

    it "have understood the type parameter" do
      Parent.allowed[0].instance_class.must_equal Allowed1
      Parent.allowed[1].instance_class.must_equal Allowed2
      Parent.allowed[2].instance_class.must_equal Allowed3
    end

    # TODO: decide on whether testing class definitions is a good idea
    # it "raise an error when given an invalid type name" do
    #   lambda { Parent.allow :WhatTheHellIsThis }.must_raise(NameError)
    # end

    it "allow all styles by default" do
      Parent.allowed[2].styles(nil).must_equal Allowed3.styles
    end

    it "have a list of allowable styles" do
      Parent.allowed[1].styles(nil).length.must_equal 2
      Parent.allowed[1].styles(nil).map { |s| s.name }.must_equal [:ringo, :george]
    end

    # TODO: decide on whether verifying style names is a good idea
    # it "raise an error if we try to use an unknown style" do
    #   lambda { Parent.allow :Allowed3, :styles => [:merlin, :arthur]  }.must_raise(Spontaneous::UnknownStyleException)
    # end

    it "use a configured style when adding a defined allowed type" do
      a = Allowable.new
      b = Allowed2.new
      a.parents << b
      a.parents.contents.first.style.prototype.must_equal Allowed2.styles[:ringo]
    end

    it "know what the available styles are for an entry" do
      a = Allowable.new
      b = Allowed2.new
      c = Allowed3.new
      a.parents << b
      a.parents << c
      a.parents.available_styles(b).map { |s| s.name }.must_equal [:ringo, :george]
      a.parents.available_styles(c).map { |s| s.name }.must_equal [:arthur, :lancelot]
    end

    it "inherit allowed types from superclass" do
      ChildClass.allowed.must_equal Parent.allowed
      Allowable.boxes.parents.allowed_types(nil).must_equal [Allowed1, Allowed2, Allowed3]
      class ::AChild < Allowable
        box :parents do
          allow :Allowed11
        end
      end
      class ::AChild2 < AChild
        box :parents, :title => "Things" do
          allow :Allowed111
        end
      end
      box = AChild.boxes.parents
      box.allowed_types(nil).must_equal [Allowed1, Allowed2, Allowed3, Allowed11]
      box = AChild2.boxes.parents
      box.title.must_equal "Things"
      box.allowed_types(nil).must_equal [Allowed1, Allowed2, Allowed3, Allowed11, Allowed111]
      Object.send(:remove_const, :AChild) rescue nil
      Object.send(:remove_const, :AChild2) rescue nil
    end

    it "include a subtype's allowed list as well as the supertype's" do
      ChildClass.allow :Allowed4
      ChildClass.allowed.map {|a| a.instance_class }.must_equal (Parent.allowed.map {|a| a.instance_class } + [Allowed4])
    end

    it "propagate allowed types to slots" do
      instance = Allowable.new
      instance.parents.allowed_types.must_equal Parent.allowed_types
    end

    it "correctly allow addition of subclasses" do
      Mixed.allowed_types.must_equal [Allowed11, Allowed111]
    end

    it "create inline classes if passed a definition block" do
      allowed = ChildClass.allow :InlineType do
        field :title
      end
      inline_type = allowed.instance_class
      inline_type.fields.length.must_equal 1
      inline_type.fields.first.name.must_equal :title
      inline_type.name.must_equal "ChildClass::InlineType"
    end

    it "use the given supertype for inline classes" do
      allowed = ChildClass.allow :InlineType, :supertype => :Allowed1 do
        field :title
      end
      inline_type = allowed.instance_class
      inline_type.ancestors[0..1].must_equal [ChildClass::InlineType, Allowed1]
    end

    it "add the created class to the schema immediately" do
      allowed = ChildClass.allow :InlineType, :supertype => :Allowed1 do
        field :title
      end
      assert @site.schema.classes.map(&:to_s).include?("ChildClass::InlineType"), "#{@site.schema.classes} does not include ChildClass::InlineType"
    end

    it "lets you define the name of the allowed type in the interface using 'as'" do
      Page.box :as, class: :AllowedAs
      page_schema = @site.schema.export['Page']
      box_schema = page_schema[:boxes].first
      allowed = box_schema[:allowed_types]
      allowed.length.must_equal 1
      defn = allowed.first
      defn.must_be_instance_of Hash
      defn[:type].must_equal "Allowed1"
      defn[:as].must_equal "Something Else"
    end
  end

  describe "Box groups" do
    before do
      class ::A < ::Piece
        box_group :inner do
          box :a
          box :b
        end
        box_group :outer do
          box :c
          box :d
        end
      end

      class ::B < ::A
        box_group :outer do
          box :e
        end
      end

      class ::C < ::B
        box :f, :group => :inner
      end

      @a = ::A.new
      @b = ::B.new
      @c = ::C.new
      [@a, @b, @c].each do |instance|
        instance.boxes[:a].stubs(:render_inline).with(anything).returns("[a]")
        instance.boxes[:b].stubs(:render_inline).with(anything).returns("[b]")
        instance.boxes[:c].stubs(:render_inline).with(anything).returns("[c]")
        instance.boxes[:d].stubs(:render_inline).with(anything).returns("[d]")
      end
      @b.boxes[:e].stubs(:render_inline).with(anything).returns("[e]")
      @c.boxes[:e].stubs(:render_inline).with(anything).returns("[e]")
      @c.boxes[:f].stubs(:render_inline).with(anything).returns("[f]")
    end

    after do
      Object.send(:remove_const, :A) rescue nil
      Object.send(:remove_const, :B) rescue nil
      Object.send(:remove_const, :C) rescue nil
    end

    it "successfully allocate boxes" do
      @a.boxes.inner.must_equal [@a.boxes[:a], @a.boxes[:b]]
      @a.boxes.outer.must_equal [@a.boxes[:c], @a.boxes[:d]]

      @b.boxes.inner.must_equal [@b.boxes[:a], @b.boxes[:b]]
      @b.boxes.outer.must_equal [@b.boxes[:c], @b.boxes[:d], @b.boxes[:e]]

      @c.boxes.inner.must_equal [@c.boxes[:a], @c.boxes[:b], @c.boxes[:f]]
      @c.boxes.outer.must_equal [@c.boxes[:c], @c.boxes[:d], @c.boxes[:e]]
    end

    it "successfully render groups" do
      @a.boxes.inner.render.must_equal "[a][b]"
      @a.boxes.outer.render.must_equal "[c][d]"

      @b.boxes.inner.render.must_equal "[a][b]"
      @b.boxes.outer.render.must_equal "[c][d][e]"

      @c.boxes.inner.render.must_equal "[a][b][f]"
      @c.boxes.outer.render.must_equal "[c][d][e]"
    end

    it "return an empty array when asking for an unknown box group" do
      @a.boxes.group(:nothing).must_equal []
    end
  end
end

