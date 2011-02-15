# encoding: UTF-8

require 'test_helper'


class SlotsTest < Test::Unit::TestCase
  include Spontaneous

  context "Slot containers" do
    setup do
      class ::SlotClass < Content; end
      class ::ContentClass < Content; end
      ContentClass.field :description
    end

    teardown do
      Object.send(:remove_const, :SlotClass)
      Object.send(:remove_const, :ContentClass)
    end

    should "start empty" do
      SlotClass.slots.length.should == 0
    end

    should "have a flag showing there are no defined slots" do
      SlotClass.has_slots?.should be_false
    end

    should "be definable with a name" do
      SlotClass.slot :images0
      SlotClass.slots.length.should == 1
      SlotClass.slots.first.name.should == :images0
      SlotClass.has_slots?.should be_true
    end

    should "accept a custom instance class" do
      SlotClass.slot :images1, :type => SlotClass
      SlotClass.slots.first.instance_class.superclass.should == SlotClass
    end

    should "accept a custom instance class as a string" do
      SlotClass.slot :images2, :type => 'SlotClass'
      SlotClass.slots.first.instance_class.superclass.should == SlotClass
    end

    should "accept a custom instance class as a symbol" do
      SlotClass.slot :images3, :type => :SlotClass
      SlotClass.slots.first.instance_class.superclass.should == SlotClass
    end

    should "have 'title' option" do
      SlotClass.slot :images4, :title => "Custom Title"
      @instance = SlotClass.new
      @instance.entries.first.slot_name.should == "Custom Title"
    end

    should "accept values for the slot's fields" do
      SlotClass.slot :images4, :type => :ContentClass, :fields => { :description => "Neato" }

      @instance = SlotClass.new
      @instance.images4.fields.description.value.should == "Neato"
    end

    should "allow access to groups of slots" do
      SlotClass.slot :images5, :tag => :main
      SlotClass.slot :posts, :tag => :main
      SlotClass.slot :comments
      SlotClass.slot :last, :tag => :main
      @instance = SlotClass.new
      @instance.slots.tagged(:main).length.should == 3
      @instance.slots.tagged('main').map {|e| e.label.to_sym }.should == [:images5, :posts, :last]
    end

    context "with superclasses" do
      setup do
        SlotClass.slot :images6, :tag => :main

        @subclass1 = Class.new(SlotClass) do
          slot :monkeys, :tag => :main
          slot :apes
        end
        @subclass2 = Class.new(@subclass1) do
          slot :peanuts
        end
      end
      should "inherit slots from its superclass" do
        @subclass2.slots.length.should == 4
        @subclass2.slots.map { |s| s.name }.should == [:images6, :monkeys, :apes, :peanuts]
        @subclass2.slots.tagged(:main).length.should == 2
        instance = @subclass2.new
        instance.slots.length.should == 4
      end

      should "allow customisation of the slot order" do
        new_order = [:peanuts, :apes, :images6, :monkeys]
        @subclass2.slot_order *new_order
        @subclass2.slots.map { |s| s.name }.should == new_order
      end

      should "take order of instance slots from class defn" do
        new_order = [:peanuts, :apes, :images6, :monkeys]
        instance = @subclass2.create
        @subclass2.slot_order *new_order
        instance = @subclass2[instance.id]
        instance.slots.map { |e| e.label.to_sym }.should == new_order
      end
    end

    # should "default to the name of the slot for the style name" do
    #   SlotClass.slot :images
    #   instance = SlotClass.new
    #   instance.images.style.filename.should == "images.html.cut"
    # end
    should "default to a template-less style for slots without a style" do
      SlotClass.slot :images7
      instance = SlotClass.new
      instance.images7.style.class.should == Spontaneous::Plugins::Styles::AnonymousStyle
    end

    should "accept a custom template name" do
      SlotClass.slot :images8, :style => :anonymous_slot
      instance = SlotClass.new
      instance.images8.style.filename.should == "anonymous_slot.html.cut"
    end

    should "take template path from slot's parent for anonymous slots" do
      SlotClass.slot :images9, :style => :anonymous_slot
      SlotClass.slot :posts
      instance = SlotClass.new
      instance.images9.style.path.should == "slot_class/anonymous_slot"
      # instance.posts.style.path.should #== "#{Spontaneous.template_root}/slot_class/posts.html.cut"
    end

    context "anonymous slots" do
      setup do
        class ::AllowedType < Content; end
        SlotClass.slot :images10 do
          allow AllowedType

          def monkey
            "magic"
          end
        end
      end

      teardown do
        Object.send(:remove_const, :AllowedType)
      end

      should "allow configuration of allowed types for anonymous slots" do
        SlotClass.slots.first.instance_class.allowed.length.should == 1
      end

      should "allow methods in slot definitions" do
        instance = SlotClass.new
        instance.images10.monkey.should == "magic"
      end

      should "correctly save entries" do
        instance = SlotClass.new
        c1 = AllowedType.new
        c2 = AllowedType.new
        c3 = AllowedType.new
        instance.images10 << c1
        instance.images10 << c2
        instance.images10 << c3

        instance.save
        instance.images10.save
        c1.save
        c2.save
        c3.save

        instance = SlotClass[instance.id]
        instance.images10.entries.length.should == 3
      end
    end

    context "slots with definied classes" do
      setup do
        class ::AllowedType < Content; end
        SlotClass.slot :images11, :type => AllowedType do
          allow AllowedType

          def monkey
            "magic"
          end
        end
      end

      teardown do
        Object.send(:remove_const, :AllowedType)
      end

      should "allow per-slot definitions" do
        SlotClass.slots.first.instance_class.allowed.length.should == 1
        instance = SlotClass.new
        instance.images11.monkey.should == "magic"
        instance = SlotClass[instance.id]
        instance.images11.monkey.should == "magic"
      end
    end
    context "" do
      setup do
        SlotClass.slot :images12
        @instance = SlotClass.new
      end

      should "provide a test for existance of named slot" do
        @instance.slot?(:images12).should be_true
        @instance.slot?(:none).should be_false
      end

      should "instantiate a corresponding piece in new instances" do
        @instance.entries.length.should == 1
        # @instance.entries.first.class.should == Piece
        @instance.entries.first.label.should == :images12
        @instance.entries.first.slot_name.should == "Images12"
      end

      should "have a #slots method for accessing slots" do
        @instance.slots.length.should == 1
        @instance.slots.first.label.should == :images12
        @instance.slots.first.slot_id.should == "images12"
        @instance.slots[:images12].should == @instance.slots.first
      end

      should "have shortcut methods for accessing slots by name" do
        @instance.slots.images12.should == @instance.slots.first
        @instance.images12.should == @instance.slots.first
      end

      should "persist slots" do
        @instance.save
        @instance = SlotClass[@instance.id]
        @instance.slots.length.should == 1
        @instance.slots.first.label.should == :images12
        @instance.slots[:images12].should == @instance.slots.first
        @instance.slots.images12.should == @instance.slots.first
        @instance.images12.should == @instance.slots.first
      end

      should "update list of slots on instance if slot added after creation" do
        @instance.save
        SlotClass.slot :posts
        @instance = SlotClass[@instance.id]
        @instance.slots.length.should == 2
        @instance.slots.first.label.should == :images12
        @instance.slots.last.label.should == :posts
        @instance.slots[:images12].should == @instance.slots.first
        @instance.slots[:posts].should == @instance.slots.last
        @instance.slots.images12.should == @instance.slots.first
        @instance.slots.posts.should == @instance.slots.last
        @instance.images12.should == @instance.slots.first
        @instance.posts.should == @instance.slots.last
      end

      ## waiting on entry deletion routines
      should "update list of slots on instance if slot removed after creation"
      # should "update list of slots on instance if slot removed after creation" do
      #   @instance.save
      #   SlotClass.slot :posts
      #   @instance = SlotClass[@instance.id]
      #   @instance.slots.length.should == 2
      #   SlotClass.slots.shift
      #   p SlotClass.slots
      #   @instance = SlotClass[@instance.id]
      #   @instance.slots.length.should == 1
      #   @instance.slots.first.label.should == "posts"
      #   @instance.slots[:posts].should == @instance.slots.first
      #   @instance.slots.posts.should == @instance.slots.first
      #   @instance.posts.should == @instance.slots.first
      # end
    end

    context "addition of slots" do
      should "be possible after creation" do
        SlotClass.slot :posts
        instance = SlotClass.new
        instance.save
        SlotClass.slot :images
        instance = SlotClass[instance.id]
        instance.images.should_not be_nil
      end
    end
  end
end
