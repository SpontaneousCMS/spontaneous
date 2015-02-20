# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)

describe "Boolean fields" do

  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
    @content_class = Class.new(::Piece)
    @prototype = @content_class.field :switch
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.create
    @field = @instance.switch
  end

  it "has a distinct editor class" do
    @prototype.instance_class.editor_class.must_equal "Spontaneous.Field.Boolean"
  end

  it "adopts any field called 'switch'" do
    assert @field.is_a?(Spontaneous::Field::Boolean), "Field should be an instance of Boolean but instead has the following ancestors #{ @prototype.instance_class.ancestors }"
  end

  it "defaults to true" do
    @field.value.must_equal true
    @field.value(:html).must_equal "Yes"
    @field.value(:string).must_equal "Yes"
  end

  it "changes string value to 'No'" do
    @field.value = false
    @field.value(:string).must_equal "No"
  end

  it "flags itself as 'empty' if false" do # I think...
    @field.empty?.must_equal false
    @field.value = false
    @field.empty?.must_equal true
  end

  it "uses the given state labels" do
    prototype = @content_class.field :boolean, true: "Enabled", false: "Disabled"
    field = prototype.to_field(@instance)
    field.value.must_equal true
    field.value(:string).must_equal "Enabled"
    field.value = false
    field.value(:string).must_equal "Disabled"
    field.value(:html).must_equal "Disabled"
  end

  it "uses the given default" do
    prototype = @content_class.field :boolean, default: false, true: "On", false: "Off"
    field = prototype.to_field(@instance)
    field.value.must_equal false
    field.value(:string).must_equal "Off"
  end

  it "returns the string value from #to_s" do
    prototype = @content_class.field :boolean, default: false, true: "On", false: "Off"
    field = prototype.to_field(@instance)
    field.to_s.must_equal "Off"
  end

  it "has shortcut accessors" do
    state = @field.value(:boolean)
    @field.on?.must_equal state
    @field.checked?.must_equal state
    @field.enabled?.must_equal state
  end

  it "exports the labels to the interface" do
    prototype = @content_class.field :boolean, default: false, true: "Yes Please", false: "No Thanks"
    exported = prototype.instance_class.export(nil)
    exported.must_equal({:labels=>{:true=>"Yes Please", :false=>"No Thanks"}})
  end
end
