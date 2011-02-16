# encoding: UTF-8

require 'test_helper'


class BoxesTest < Test::Unit::TestCase

  context "Box definitions" do
    setup do
      class ::MyBoxClass < Box; end
      class ::MyContentClass < Content; end
      class ::MyContentClass2 < MyContentClass; end
      MyContentClass.field :description
    end

    teardown do
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
      instance.images1.class.should == Box
      instance.images2.class.should == MyBoxClass
    end

    should "be available by name" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      MyContentClass.boxes[:images1].should == MyContentClass.boxes.first
      MyContentClass.boxes[:images2].should == MyContentClass.boxes.last
      instance = MyContentClass.new
      instance.boxes[:images1].class.should == Box
      instance.boxes[:images2].class.should == MyBoxClass
    end

    should "accept a custom instance class" do
      MyContentClass.box :images1, :type => MyBoxClass
      MyContentClass.boxes.first.instance_class.should == MyBoxClass
    end

    should "accept a custom instance class as a string" do
      MyContentClass.box :images1, :type => 'MyBoxClass'
      MyContentClass.boxes.first.instance_class.should == MyBoxClass
    end

    should "accept a custom instance class as a symbol" do
      MyContentClass.box :images1, :type => :MyBoxClass
      MyContentClass.boxes.first.instance_class.should == MyBoxClass
    end

    should "Instantiate a box of the correct class" do
      MyContentClass.box :images1
      MyContentClass.box :images2, :type => :MyBoxClass
      instance = MyContentClass.new
      instance.boxes.first.class.should == Box
      instance.boxes.last.class.should == MyBoxClass
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
      instance.images1.class.should == MyBoxClass
      instance.images2.class.should == Box
      instance.boxes.length.should == 2
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
      Spontaneous.template_root = File.expand_path('../../fixtures/templates/boxes', __FILE__)
      class ::MyContentClass < Content; end
      class ::MyBoxClass < Box; end
      MyContentClass.box :images, :class => :MyBoxClass, :fields => {
        :title => "Default Title",
        :description => "Default Description"
      }
      @content = MyContentClass.new
    end

    teardown do
      Object.send(:remove_const, :MyContentClass)
      Object.send(:remove_const, :MyBoxClass)
    end

    should "have fields" do
      MyBoxClass.fields.length.should == 0
      MyBoxClass.field :title, :string
      MyBoxClass.fields.length.should == 1
    end

    context "with fields" do
      setup do
        MyBoxClass.field :title, :string
        MyBoxClass.field :description, :text
      end

      should "save their field values" do
        @content.images.title = "something"
        @content.images.description = "description here"
        @content.save
        @content.reload
        @content.images.title.value.should == "something"
        @content.images.description.value.should == "description here"
      end

      should "take initialvalues from box definition" do
        @content.images.title.value.should == "Default Title"
        @content.images.description.value.should == "Default Description"
      end
    end

    should "allow inline definition of fields" do
      MyContentClass.box :partners do
        field :name, :string
        field :logo, :image
        field :description, :text
      end
      instance = MyContentClass.new
      instance.partners.name.should be_instance_of(Spontaneous::FieldTypes::StringField)
      instance.partners.name = "Howard"
      instance.partners.description = "Here is Howard"
      instance.save
      instance = Content[instance.id]
      instance.partners.name.value.should == "Howard"
      instance.partners.description.value.should == "Here is Howard"
    end

    should "default to template in root with the same name" do
    end

    context "with styles" do
      setup do
        MyBoxClass.field :title, :string
        MyBoxClass.inline_style :christy
        class ::InheritedStyleBox < MyBoxClass; end
        class ::WithTemplateBox < Box; end
        class ::WithoutTemplateBox < Box; end
        class ::BlankContent < Content; end
        @content = MyContentClass.new
        @content.images.title = "whisty"
      end

      teardown do
        Object.send(:remove_const, :InheritedStyleBox)
        Object.send(:remove_const, :WithTemplateBox)
        Object.send(:remove_const, :WithoutTemplateBox)
      end

      should_eventually "render using explicit styles" do
        @content.images.render.should == "christy: whisty\n"
      end

      should_eventually "allow defining style in definition" do
        BlankContent.box :images do
          inline_style :inline_style
        end
        instance = BlankContent.new
        instance.images.style.filename.should == "inline_style.html.cut"
      end

      should_eventually "render using default template style" do
        BlankContent.box :images, :class => :WithTemplateBox
        instance = BlankContent.new
        instance.images.render.should == "with_template_box.html.cut\n"
      end

      should_eventually "render using global default box styles" do
        entry = Object.new
        entry.stubs(:render).returns("<entry>")
        BlankContent.box :images, :class => :WithoutTemplateBox
        instance = BlankContent.new
        instance.images.stubs(:entries).returns([entry])
        instance.images.render.should == "<entry>"
      end

      should_eventually "inherit styles from their superclass" do
        BlankContent.box :images, :class => :InheritedStyleBox
        instance = BlankContent.new
        instance.images.title = "ytsirhc"
        instance.images.render.should == "christy: ytsirhc\n"
      end
    end

  end

  context "Box content" do
    setup do
      class ::BlankContent < Content; end
      class ::StyledContent < Content; end
      BlankContent.inline_style :blank1
      BlankContent.inline_style :blank2
      BlankContent.inline_style :blank3
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
      Object.send(:remove_const, :BlankContent)
      Object.send(:remove_const, :StyledContent)
    end

    should "be addable" do
      child1 = BlankContent.new
      child2 = BlankContent.new
      child3 = BlankContent.new
      @parent.images << child1
      @parent.words << child2
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
  end
end

