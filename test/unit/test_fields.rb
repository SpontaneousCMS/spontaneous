
require 'test_helper'
class FieldsTest < Test::Unit::TestCase
  include Spontaneous

  context "New content instances" do
    setup do
      @content_class = Class.new(Content) do
        field :title, :default_value => "Magic"
        field :thumbnail, :class => Spontaneous::FieldTypes::Image
      end
      @instance = @content_class.new
    end

    should "have fields with values defined by prototypes" do
      f = @instance.fields[:title]
      f.should be_instance_of Spontaneous::FieldTypes::Text
      f.value.should == "Magic"
    end

    should "have shortcut access methods to fields" do
      @instance.fields.thumbnail.should == @instance.fields[:thumbnail]
    end
  end
end
