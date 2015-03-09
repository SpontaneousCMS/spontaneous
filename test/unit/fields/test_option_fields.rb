# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)

describe "Option fields" do
  before do
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
    @content_class = Class.new(::Piece) do
      field :options, :select, :options => [
        ["a", "Value A"],
        ["b", "Value B"],
        ["c", "Value C"]
      ]
    end
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.new
    @field = @instance.options
  end

  it "use a specific editor class" do
    @content_class.fields.options.export(nil)[:type].must_equal "Spontaneous.Field.Select"
  end

  it "select the options class for fields named options" do
    @content_class.field :type, :select, :options => [["a", "A"]]
    assert @content_class.fields.options.instance_class.ancestors.include?(Spontaneous::Field::Select)
  end

  it "accept a list of strings as options" do
    @content_class.field :type, :select, :options => ["a", "b"]
    @instance = @content_class.new
    @instance.type.option_list.must_equal [["a", "a"], ["b", "b"]]
  end

  it "accept a json string as a value and convert it properly" do
    @field.value = %(["a", "Value A"])
    @field.value.must_equal "a"
    @field.value(:label).must_equal "Value A"
    @field.label.must_equal "Value A"
    @field.unprocessed_value.must_equal %(["a", "Value A"])
  end

  it 'allows for the setting of a default value' do
    @content_class.field :type, :select, :options => [["a", "A Label"], ["b", "B Label"], ["c", "C Label"]], default: "b"
    @instance = @content_class.new
    @instance.type.value.must_equal "b"
    @instance.type.value(:label).must_equal "B Label"
  end

  it 'exports properly with a null value' do
    @content_class.field :type, :select, :options => [["a", "A Label"], ["b", "B Label"], ["c", "C Label"]]
    @instance = @content_class.new
    e = @instance.fields[:type].export(nil)
    e[:unprocessed_value].must_equal ""
    e[:processed_value].must_equal ""
  end
end
