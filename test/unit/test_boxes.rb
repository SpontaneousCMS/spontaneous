# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class BoxesTest < MiniTest::Spec

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Box definitions" do
    setup do

      class ::Piece < Spontaneous::Piece; end
      class ::MyBoxClass < Box; end
      class ::MyContentClass < Piece; end
      class ::MyContentClass2 < MyContentClass; end
      MyContentClass.field :description
    end

    teardown do
      Object.send(:remove_const, :Piece)
      Object.send(:remove_const, :MyContentClass2)
      Object.send(:remove_const, :MyContentClass)
      Object.send(:remove_const, :MyBoxClass)
    end

    should "start empty" do
      MyContentClass.boxes.length.should == 0
    end

    should "have a flag showing there are no defined boxes" do
      MyContentClass.has_boxes?.should be_false
    end

    should "be definable with a name" do
      MyContentClass.box :images0
      MyContentClass.boxes.length.should == 1
      MyContentClass.boxes.first.name.should == :images0
      MyContentClass.has_boxes?.should be_true
    end

    should "always return a symbol for the name" do
      MyContentClass.box 'images0'
      MyContentClass.boxes.first.name.should == :images0
    end

    should "create a method of the same name" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      instance = MyContentClass.new
      instance.images1.class.superclass.should == Box
      instance.images2.class.superclass.should == MyBoxClass
    end

    should "be available by name" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      MyContentClass.boxes[:images1].should == MyContentClass.boxes.first
      MyContentClass.boxes[:images2].should == MyContentClass.boxes.last
      instance = MyContentClass.new
      instance.boxes[:images1].class.superclass.should == Box
      instance.boxes[:images2].class.superclass.should == MyBoxClass
    end

    should "accept a custom instance class" do
      MyContentClass.box :images1, :type => MyBoxClass
      MyContentClass.boxes.first.instance_class.superclass.should == MyBoxClass
    end

    should "accept a custom instance class as a string" do
      MyContentClass.box :images1, :type => 'MyBoxClass'
      MyContentClass.boxes.first.instance_class.superclass.should == MyBoxClass
    end

    should "accept a custom instance class as a symbol" do
      MyContentClass.box :images1, :type => :MyBoxClass
      MyContentClass.boxes.first.instance_class.superclass.should == MyBoxClass
    end

    should "Instantiate a box of the correct class" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      instance = MyContentClass.new
      instance.boxes.first.class.superclass.should == Box
      instance.boxes.last.class.superclass.should == MyBoxClass
    end

    should "give access to the prototype within the instance" do
      MyContentClass.box :images1
      instance = MyContentClass.new
      instance.boxes[:images1]._prototype.should == MyContentClass.boxes[:images1]
    end

    should "Use the name as the title by default" do
      MyContentClass.box :band_and_band
      MyContentClass.box :related_items
      MyContentClass.boxes.first.title.should == "Band & Band"
      MyContentClass.boxes.last.title.should == "Related Items"
    end

    should "have 'title' option" do
      MyContentClass.box :images4, :title => "Custom Title"
      MyContentClass.boxes.first.title.should == "Custom Title"
    end

    should "inherit boxes from superclass" do
      MyContentClass.box :images1, :type => :MyBoxClass
      MyContentClass2.box :images2
      MyContentClass2.boxes.length.should == 2
      instance = MyContentClass2.new
      instance.images1.class.superclass.should == MyBoxClass
      instance.images2.class.superclass.should == Box
      instance.boxes.length.should == 2
    end

    should "know their ordering in the container" do
      MyContentClass.box :box1
      MyContentClass.box :box2
      MyContentClass.box :box3
      MyContentClass.box_order :box3, :box2, :box1
      MyContentClass.boxes.box3.position.should == 0
      MyContentClass.boxes.box2.position.should == 1
      MyContentClass.boxes.box1.position.should == 2
      instance = MyContentClass.new
      instance.box3.position.should == 0
      instance.box2.position.should == 1
      instance.box1.position.should == 2
    end

    context "ranges" do
      setup do
        MyContentClass.box :images1
        MyContentClass.box :images2
        MyContentClass.box :images3
        MyContentClass.box :images4
        MyContentClass.box :images5
        MyContentClass2.box :images6
        @instance = MyContentClass.new
        @instance2 = MyContentClass2.new
      end
      should "allow access to groups of boxes through ranges" do
        @instance.boxes[1..-2].map { |b| b.box_name }.should == [:images2, :images3, :images4]
        @instance2.boxes[1..-2].map { |b| b.box_name }.should == [:images2, :images3, :images4, :images5]
      end

      should "allow you to pass a list of names" do
        @instance.boxes[:images1, :images4].map { |b| b.box_name }.should == [:images1, :images4]
        @instance2.boxes[:images1, :images6].map { |b| b.box_name }.should == [:images1, :images6]
      end

      should "allow a mix of names and indexes" do
        @instance.boxes[0..2, :images5].map { |b| b.box_name }.should == [:images1, :images2, :images3, :images5]
      end
      should "allow access to groups of boxes through tags"
      #   MyContentClass.box :images5, :tag => :main
      #   MyContentClass.box :posts, :tag => :main
      #   MyContentClass.box :comments
      #   MyContentClass.box :last, :tag => :main
      #   @instance = MyBoxClass.new
      #   @instance.boxes.tagged(:main).length.should == 3
      #   @instance.boxes.tagged('main').map {|e| e.name }.should == [:images5, :posts, :last]
      # end
    end
    context "with superclasses" do
      setup do
        MyContentClass.box :images6, :tag => :main

        @subclass1 = Class.new(MyContentClass) do
          box :monkeys, :tag => :main
          box :apes
        end
        @subclass2 = Class.new(@subclass1) do
          box :peanuts
        end
      end
      should "inherit boxes from its superclass" do
        @subclass2.boxes.length.should == 4
        @subclass2.boxes.map { |s| s.name }.should == [:images6, :monkeys, :apes, :peanuts]
        # @subclass2.boxes.tagged(:main).length.should == 2
        instance = @subclass2.new
        instance.boxes.length.should == 4
      end

      should "allow customisation of the box order" do
        new_order = [:peanuts, :apes, :images6, :monkeys]
        @subclass2.box_order *new_order
        @subclass2.boxes.map { |s| s.name }.should == new_order
      end

      should "take order of instance boxes from class defn" do
        new_order = [:peanuts, :apes, :images6, :monkeys]
        @subclass2.box_order *new_order
        instance = @subclass2.new
        instance.boxes.map { |e| e.box_name.to_sym }.should == new_order
      end
    end



    should "accept values for the box's fields"
    should "allow overwriting of class definitions using a block"
  end

  context "Box classes" do
    setup do
      @site.stubs(:template_root).returns(File.expand_path('../../fixtures/templates/boxes', __FILE__))
      class ::Piece < Spontaneous::Piece; end
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

    teardown do
      Object.send(:remove_const, :Piece)
      Object.send(:remove_const, :MyContentClass)
      Object.send(:remove_const, :MyBoxClass)
    end

    should "have fields" do
      MyBoxClass.fields.length.should == 2
      MyBoxClass.field :another, :string
      MyBoxClass.fields.length.should == 3
    end

    context "with fields" do

      should "save their field values" do
        @content.images.title = "something"
        @content.images.description = "description here"
        @content.save
        @content.reload
        @content.images.title.value.should == "something"
        @content.images.description.value.should == "description here"
      end

      should "take initial values from box definition" do
        @content.images.title.value.should == "Default Title"
        @content.images.description.value.should == "Default Description"
      end
    end

    should "allow inline definition of fields" do
      MyContentClass.box :partners do
        field :name, :string
        field :logo, :image
        field :description, :string
      end
      instance = MyContentClass.new
      instance.partners.name.must_be_instance_of(Spontaneous::FieldTypes::StringField)
      instance.partners.name = "Howard"
      instance.partners.description = "Here is Howard"
      instance.save
      instance = Content[instance.id]
      instance.partners.name.value.should == "Howard"
      instance.partners.description.value.should == "Here is Howard"
    end

    should "default to template in root with the same name" do
    end

    # context "with styles" do
    #   setup do
    #     MyBoxClass.field :title, :string
    #     MyBoxClass.style :christy
    #     class ::InheritedStyleBox < MyBoxClass; end
    #     class ::WithTemplateBox < Box; end
    #     class ::WithoutTemplateBox < Box; end
    #     class ::BlankContent < Content; end
    #     @content = MyContentClass.new
    #     @content.images.title = "whisty"
    #   end

    #   teardown do
    #     Object.send(:remove_const, :InheritedStyleBox)
    #     Object.send(:remove_const, :WithTemplateBox)
    #     Object.send(:remove_const, :WithoutTemplateBox)
    #     Object.send(:remove_const, :BlankContent)
    #   end

    #   should "render using explicit styles" do
    #     @content.images.render.should == "christy: whisty\\n"
    #   end

    #   should_eventually "allow defining style in definition" do
    #     BlankContent.box :images do
    #       style :inline_style
    #     end
    #     instance = BlankContent.new
    #     instance.images.style.filename.should == "inline_style.html.cut"
    #   end

    #   should "render using default template style" do
    #     BlankContent.box :images, :class => :WithTemplateBox
    #     instance = BlankContent.new
    #     instance.images.render.should == "with_template_box.html.cut\\n"
    #   end

    #   should "render using global default box styles" do
    #     entry = Object.new
    #     entry.stubs(:render).returns("<entry>")
    #     BlankContent.box :images, :class => :WithoutTemplateBox
    #     instance = BlankContent.new
    #     instance.images.stubs(:pieces).returns([entry])
    #     instance.images.render.should == "<entry>"
    #   end

    #   should "find templates named after box in owning classes template dir" do
    #     BlankContent.box :things
    #     instance = BlankContent.new
    #     instance.things.render.should == "blank_content/things.html.cut\\n"
    #   end

    #   should "not use templates with box name found in root template dir" do
    #     BlankContent.box :thangs
    #     instance = BlankContent.new
    #     instance.thangs.render.should == ""
    #   end

    #   should "inherit styles from their superclass" do
    #     BlankContent.box :images, :class => :InheritedStyleBox
    #     instance = BlankContent.new
    #     instance.images.title = "ytsirhc"
    #     instance.images.render.should == "christy: ytsirhc\\n"
    #   end
    # end

  end

  context "Box content" do
    setup do
      class ::Piece < Spontaneous::Piece; end
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

    teardown do
      Object.send(:remove_const, :Piece)
      Object.send(:remove_const, :BlankContent)
      Object.send(:remove_const, :StyledContent)
    end

    should "be addable" do
      child1 = BlankContent.new
      child2 = BlankContent.new
      child3 = BlankContent.new
      @parent.images << child1
      @parent.words << child2
      child1.box.schema_id.should == @parent.images.schema_id
      child2.box.schema_id.should == @parent.words.schema_id
      @parent.save
      child1.images << child3
      child1.save
      @parent = Content[@parent.id]
      child1.reload; child2.reload; child3.reload
      @parent.images.pieces.should == [child1]
      @parent.words.pieces.should == [child2]
      @parent.pieces.should == [child1, child2]
      child1.images.pieces.should == [child3]
      child1.pieces.should == [child3]

      @parent.images.pieces.first.box.should == @parent.images
      @parent.words.pieces.first.box.should == @parent.words
      @parent.pieces.first.box.should == @parent.images
    end

    should "choose correct style" do
      styled = StyledContent.new
      child1 = BlankContent.new
      child2 = BlankContent.new
      child3 = BlankContent.new
      styled.one << child1
      styled.two << child2
      styled.save
      styled = Content[styled.id]
      styled.one.pieces.first.style.name.should == :blank2
      styled.two.pieces.first.style.name.should == :blank3
    end

    should "allow selection of subclasses" do
    end
  end

  context "Allowed types" do
    setup do
      class ::Allowed1 < Content
        style :frank
        style :freddy
      end
      class ::Allowed2 < Content
        style :john
        style :paul
        style :ringo
        style :george
      end
      class ::Allowed3 < Content
        style :arthur
        style :lancelot
      end
      class ::Allowed4 < Content; end

      class ::Allowed11 < ::Allowed1; end
      class ::Allowed111 < ::Allowed1; end

      class ::Parent < Box
        allow :Allowed1
        allow Allowed2, :styles => [:ringo, :george]
        allow 'Allowed3'
      end

      class ::ChildClass < ::Parent
      end

      class ::Allowable < Content
        box :parents, :type => :Parent
      end

      class ::Mixed < Box
        allow_subclasses :Allowed1
      end
    end

    teardown do
      [:Parent, :Allowed1, :Allowed11, :Allowed111, :Allowed2, :Allowed3, :Allowed4, :ChildClass, :Allowable, :Mixed].each { |k| Object.send(:remove_const, k) } rescue nil
    end

    should "have a list of allowed types" do
      Parent.allowed.length.should == 3
    end

    should "have understood the type parameter" do
      Parent.allowed[0].instance_class.should == Allowed1
      Parent.allowed[1].instance_class.should == Allowed2
      Parent.allowed[2].instance_class.should == Allowed3
    end

    # TODO: decide on whether testing class definitions is a good idea
    # should "raise an error when given an invalid type name" do
    #   lambda { Parent.allow :WhatTheHellIsThis }.must_raise(NameError)
    # end

    should "allow all styles by default" do
      Parent.allowed[2].styles.should == Allowed3.styles
    end

    should "have a list of allowable styles" do
      Parent.allowed[1].styles.length.should == 2
      Parent.allowed[1].styles.map { |s| s.name }.should == [:ringo, :george]
    end

    # TODO: decide on whether verifying style names is a good idea
    # should "raise an error if we try to use an unknown style" do
    #   lambda { Parent.allow :Allowed3, :styles => [:merlin, :arthur]  }.must_raise(Spontaneous::UnknownStyleException)
    # end

    should "use a configured style when adding a defined allowed type" do
      a = Allowable.new
      b = Allowed2.new
      a.parents << b
      a.parents.pieces.first.style.prototype.should == Allowed2.styles[:ringo]
    end

    should "know what the available styles are for an entry" do
      a = Allowable.new
      b = Allowed2.new
      c = Allowed3.new
      a.parents << b
      a.parents << c
      a.parents.available_styles(b).map { |s| s.name }.should == [:ringo, :george]
      a.parents.available_styles(c).map { |s| s.name }.should == [:arthur, :lancelot]
    end

    should "inherit allowed types from superclass" do
      ChildClass.allowed.should == Parent.allowed
    end

    should "include a subtype's allowed list as well as the supertype's" do
      ChildClass.allow :Allowed4
      ChildClass.allowed.map {|a| a.instance_class }.should == (Parent.allowed.map {|a| a.instance_class } + [Allowed4])
    end

    should "propagate allowed types to slots" do
      instance = Allowable.new
      instance.parents.allowed_types.should == Parent.allowed_types
    end

    should "correctly allow addition of subclasses" do
      Mixed.allowed_types.should == [Allowed11, Allowed111]
    end
  end

  context "Box groups" do
    setup do
      class ::A < S::Piece
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
        instance.boxes[:a].stubs(:render).with(anything).returns("[a]")
        instance.boxes[:b].stubs(:render).with(anything).returns("[b]")
        instance.boxes[:c].stubs(:render).with(anything).returns("[c]")
        instance.boxes[:d].stubs(:render).with(anything).returns("[d]")
      end
      @b.boxes[:e].stubs(:render).with(anything).returns("[e]")
      @c.boxes[:e].stubs(:render).with(anything).returns("[e]")
      @c.boxes[:f].stubs(:render).with(anything).returns("[f]")
    end

    teardown do
      Object.send(:remove_const, :A)
      Object.send(:remove_const, :B)
      Object.send(:remove_const, :C)
    end

    should "successfully allocate boxes" do
      @a.boxes.inner.render.should == "[a][b]"
      @a.boxes.outer.render.should == "[c][d]"

      @b.boxes.inner.render.should == "[a][b]"
      @b.boxes.outer.render.should == "[c][d][e]"

      @c.boxes.inner.render.should == "[a][b][f]"
      @c.boxes.outer.render.should == "[c][d][e]"
    end
  end
end

