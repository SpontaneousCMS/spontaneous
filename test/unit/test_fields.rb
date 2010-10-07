require 'test_helper'

class FieldsTest < Test::Unit::TestCase
  include Spontaneous

  context "New content instances" do
    setup do
      @content_class = Class.new(Content) do
        field :title, :default_value => "Magic"
        field :thumbnail, :image
      end
      @instance = @content_class.new
    end

    should "have fields with values defined by prototypes" do
      f = @instance.fields[:title]
      f.class.should == Spontaneous::FieldTypes::Text
      f.value.should == "Magic"
    end

    should "have shortcut access methods to fields" do
      @instance.fields.thumbnail.should == @instance.fields[:thumbnail]
    end
    should "have a shortcut setter on the Content fields" do
      @instance.fields.title = "New Title"
    end

    should "have a shortcut getter on the Content instance itself" do
      @instance.title.should == @instance.fields[:title]
    end

    should "have a shortcut setter on the Content instance itself" do
      @instance.title = "Boing!"
      @instance.fields[:title].value.should == "Boing!"
    end
  end

  context "Values" do
    setup do
      @field_class = Class.new(Field) do
        def process(value)
          "<#{value}>"
        end
      end
      @field = @field_class.new()
    end

    should "be transformed by the update method" do
      @field.value = "Hello"
      @field.value.should == "<Hello>"
      @field.unprocessed_value.should == "Hello"
    end

    should "appear in the to_s method" do
      @field.value = "String"
      @field.to_s.should == "<String>"
    end
  end

  context "Passing blocks to prototypes" do
    setup do
      CC = Class.new(Content) do
        field :title, :default_value => "Magic" do
          def process(value)
            "*#{value}*"
          end
        end
      end
      @instance = CC.new
    end

    should "be eval'd by the field class" do
      f = @instance.fields.title
      f.value = "Boo"
      f.value.should == "*Boo*"
      f.unprocessed_value.should == "Boo"
    end
  end

  context "Field value persistence" do
    setup do
      @content_class = Class.new(Content) do
        field :title, :default_value => "Magic"
      end
    end
    should "work" do
      instance = @content_class.new
      instance.fields.title.value = "Changed"
      instance.save
      id = instance.id
      instance = @content_class[id]
      instance.fields.title.value.should == "Changed"
    end

  end
end
