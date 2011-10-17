# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class PrototypesTest < MiniTest::Spec
  context "Prototypes" do
    setup do
      class ::ImageClass < Spontaneous::Piece
        field :image
        field :description

        prototype do |piece|
          piece.description = "An Image"
        end

        prototype :complex do |piece|
          piece.description = "Complex"
        end
      end

      class ::PrototypeClass < Spontaneous::Piece
        field :title, :string
        field :date,  :string
        field :something, :string, :default => "Here"

        box :images

        prototype do |piece|
          piece.title = "Naughty"
          piece.date  = "Yesterday"
          piece.something = piece.something.value * 2
          piece.images << ImageClass.new
        end

        prototype :careless do |piece|
          piece.title = "Careless"
          piece.date  = "Whisper"
        end

        prototype :witless do |piece|
          piece.title = "Witless"
          piece.date  = "Witness"
        end
      end


    end
    teardown do
      Content.delete
      Object.send(:remove_const, :ImageClass) rescue nil
      Object.send(:remove_const, :PrototypeClass) rescue nil
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

    should "allow boxes to define the prototype used when adding items" do
      PrototypeClass.box :images2 do
        allow :ImageClass, :prototype => :complex
      end
      content = PrototypeClass.create
      content.images2 << ImageClass.new
      content.images2.first.description.value.should == "Complex"
    end

    should "allow creation by-passing the prototype" do
      content = PrototypeClass.create_without_prototype
      content.title.value.should == ""
      content.date.value.should == ""
    end

    should "inherit prototypes from supertype" do
      class ::Prototype2Class < ::PrototypeClass; end

      content = Prototype2Class.create(:witless)
      content.title.value.should == "Witless"
      content.date.value.should == "Witness"

      Object.send(:remove_const, :ImageClass) rescue nil
    end
  end
end

