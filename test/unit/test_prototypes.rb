# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Prototypes" do
  before do
    @site = setup_site
    class ::ImageClass < ::Piece
      field :image
      field :description

      prototype do |piece|
        piece.description = "An Image"
      end

      prototype :complex do |piece|
        piece.description = "Complex"
      end
    end

    class ::PrototypeClass < ::Piece
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

  after do
    Content.delete
    Object.send(:remove_const, :ImageClass) rescue nil
    Object.send(:remove_const, :PrototypeClass) rescue nil
    teardown_site
  end

  it "call #prototype after creation of an object" do
    content = PrototypeClass.create
    content.title.value.must_equal "Naughty"
    content.date.value.must_equal "Yesterday"
    content.images.entries.length.must_equal 1
    content.images.first.description.value.must_equal "An Image"
  end

  it "already have default values in fields on calling prototype" do
    content = PrototypeClass.create
    content.something.value.must_equal "HereHere"
  end

  it "call appropriate prototype if passed a prototype name" do
    content = PrototypeClass.create
    content.title.value.must_equal "Naughty"
    content.date.value.must_equal "Yesterday"

    content = PrototypeClass.create(:careless)
    content.title.value.must_equal "Careless"
    content.date.value.must_equal "Whisper"

    content = PrototypeClass.create(:witless)
    content.title.value.must_equal "Witless"
    content.date.value.must_equal "Witness"
  end

  it "not cause an error if an invalid prototype name is passed" do
    content = PrototypeClass.create(:nothing)
    content.title.value.must_equal ""
    content.date.value.must_equal ""
  end

  it "allow boxes to define the prototype used when adding items" do
    PrototypeClass.box :images2 do
      allow :ImageClass, :prototype => :complex
    end
    content = PrototypeClass.create
    content.images2 << ImageClass.new
    content.images2.first.description.value.must_equal "Complex"
  end

  it "allow creation by-passing the prototype" do
    content = PrototypeClass.create_without_prototype
    content.title.value.must_equal ""
    content.date.value.must_equal ""
  end

  it "inherit prototypes from supertype" do
    class ::Prototype2Class < ::PrototypeClass; end

    content = Prototype2Class.create(:witless)
    content.title.value.must_equal "Witless"
    content.date.value.must_equal "Witness"

    Object.send(:remove_const, :Prototype2Class) rescue nil
  end

  it "allow overwriting of prototypes in subclasses" do
    class ::Prototype2Class < ::PrototypeClass
      prototype :witless do |piece|
        piece.title = "Witless2"
        piece.date  = "Witness2"
      end
    end

    content = Prototype2Class.create(:witless)
    content.title.value.must_equal "Witless2"
    content.date.value.must_equal "Witness2"

    Object.send(:remove_const, :Prototype2Class) rescue nil
  end

  it "allow calling of supertype prototype from within overridden prototype" do
    class ::Prototype2Class < ::PrototypeClass
      prototype :witless do |piece|
        super(piece)
        piece.date  = "Witness2"
      end
    end

    content = Prototype2Class.create(:witless)
    content.title.value.must_equal "Witless"
    content.date.value.must_equal "Witness2"

    Object.send(:remove_const, :Prototype2Class) rescue nil
  end

  it "raise error if definition does not accept exactly 1 argument" do
    begin
      class ::Prototype3Class < ::Piece
        prototype {}
      end
      flunk("Defining prototypes with no arguments should raise error")
    rescue => e
      e.must_be_instance_of(Spontaneous::InvalidPrototypeDefinitionError)
    end
    Object.send(:remove_const, :Prototype3Class) rescue nil
  end
end
