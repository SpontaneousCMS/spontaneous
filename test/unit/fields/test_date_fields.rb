# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)

describe "Date fields" do
  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
    @content_class = Class.new(::Piece)
    @prototype = @content_class.field :date
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.create
    @field = @instance.date
  end

  it "have a distinct editor class" do
    @prototype.instance_class.editor_class.must_equal "Spontaneous.Field.Date"
  end

  it "adopt any field called 'date'" do
    assert @field.is_a?(Spontaneous::Field::Date), "Field should be an instance of DateField but instead has the following ancestors #{ @prototype.instance_class.ancestors }"
  end

  it "default to an empty string" do
    @field.value(:html).must_equal ""
    @field.value(:plain).must_equal ""
  end

  it "correctly parse strings" do
    @field.value = "Friday, 8 June, 2012"
    @field.value(:html).must_equal %(<time datetime="2012-06-08">Friday, 8 June, 2012</time>)
    @field.value(:plain).must_equal %(Friday, 8 June, 2012)
    @field.date.must_equal Date.parse("Friday, 8 June, 2012")
  end

  it "allow for setting a custom default format" do
    prototype = @content_class.field :datef, :date, :format => "%d %b %Y, %a"
    instance = @content_class.new
    field = instance.datef
    field.value = "Friday, 8 June, 2012"
    field.value(:html).must_equal %(<time datetime="2012-06-08">08 Jun 2012, Fri</time>)
    field.value(:plain).must_equal %(08 Jun 2012, Fri)
  end
end
