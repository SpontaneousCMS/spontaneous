# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)

describe "Tag list fields" do
  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
    @content_class = Class.new(::Piece)
    @prototype = @content_class.field :tags
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.create
    @field = @instance.tags
  end

  it "has a distinct editor class" # eventually...

  it "adopts any field called 'tags'" do
    assert @field.is_a?(Spontaneous::Field::Tags), "Field should be an instance of TagsField but instead has the following ancestors #{ @prototype.instance_class.ancestors }"
  end

  it "defaults to an empty list" do
    @field.value(:html).must_equal ""
    @field.value(:tags).must_equal []
  end

  it "correctly parses strings" do
    @field.value = 'this that "the other" more'
    @field.value(:html).must_equal 'this that "the other" more'
    @field.value(:tags).must_equal ["this", "that", "the other", "more"]
  end

  it "includes Enumerable" do
    @field.value = 'this that "the other" more'
    @field.map(&:upcase).must_equal  ["THIS", "THAT", "THE OTHER", "MORE"]
  end

  it "allows for tags with commas" do
    @field.value = %(this that "the, other" more)
    @field.map(&:upcase).must_equal  ["THIS", "THAT", "THE, OTHER", "MORE"]
  end
end
