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

    should "allow access to groups of boxes through tags"
    should "allow access to groups of boxes through ranges"
    #   MyContentClass.box :images5, :tag => :main
    #   MyContentClass.box :posts, :tag => :main
    #   MyContentClass.box :comments
    #   MyContentClass.box :last, :tag => :main
    #   @instance = MyBoxClass.new
    #   @instance.boxes.tagged(:main).length.should == 3
    #   @instance.boxes.tagged('main').map {|e| e.name }.should == [:images5, :posts, :last]
    # end

    should "accept values for the box's fields"
  end
end

