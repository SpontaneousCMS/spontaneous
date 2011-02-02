# encoding: UTF-8

require 'test_helper'

class PrototypesTest < Test::Unit::TestCase
  context "Prototypes" do
    setup do
      class ::ImageClass < Spontaneous::Content
        field :image
        field :description

        def prototype
          self.description = "An Image"
        end

        def complex_prototype
          self.description = "Complex"
        end
      end

      class ::PrototypeClass < Spontaneous::Content
        field :title, :string
        field :date,  :string
        field :something, :string, :default_value => "Here"

        slot :images

        def prototype
          self.title = "Naughty"
          self.date  = "Yesterday"
          self.something = self.something.value * 2
          self.images << ImageClass.new
        end

        def careless_prototype
          self.title = "Careless"
          self.date  = "Whisper"
        end

        def witless_prototype
          self.title = "Witless"
          self.date  = "Witness"
        end
      end

    end
    teardown do
      Content.delete
      Object.send(:remove_const, :ImageClass)
      Object.send(:remove_const, :PrototypeClass)
    end

    should "call #prototype after creation of an object" do
      content = PrototypeClass.create
      content.title.value.should == "Naughty"
      content.date.value.should == "Yesterday"
      content.images.entries.length.should == 1
      content.images.first.description.value.should == "An Image"
    end

    should "already have default values in fields on calling prototype" do
      content = PrototypeClass.create
      content.something.value.should == "HereHere"
    end

    should "call appropriate prototype if passed a prototype name" do
      content = PrototypeClass.create
      content.title.value.should == "Naughty"
      content.date.value.should == "Yesterday"

      content = PrototypeClass.create(:careless)
      content.title.value.should == "Careless"
      content.date.value.should == "Whisper"

      content = PrototypeClass.create(:witless)
      content.title.value.should == "Witless"
      content.date.value.should == "Witness"
    end

    should "not cause an error if an invalid prototype name is passed" do
      content = PrototypeClass.create(:nothing)
      content.title.value.should == ""
      content.date.value.should == ""
    end

    should "allow slots to define the prototype used when adding items" do
      PrototypeClass.slot :images2 do
        allow :ImageClass, :prototype => :complex
      end
      content = PrototypeClass.create
      content.images2 << ImageClass.new
      content.images2.first.description.value.should == "Complex"
    end
  end
end

