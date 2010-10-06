require 'test_helper'


class SchemasTest < Test::Unit::TestCase
  include Spontaneous

  context "Configurable names" do
    setup do
      class FunkyContent < Content; end
      class MoreFunkyContent < FunkyContent; end
      class ABCDifficultName < Content; end

      class CustomName < ABCDifficultName
        name "Some Name"
      end
    end

    should "1. default to generated version" do
      FunkyContent.default_name.should == "Funky Content"
      FunkyContent.name.should == "Funky Content"
      MoreFunkyContent.name.should == "More Funky Content"
      ABCDifficultName.default_name.should == "ABC Difficult Name"
      ABCDifficultName.name.should == "ABC Difficult Name"
    end

    should "2. be settable" do
      CustomName.name.should == "Some Name"
      FunkyContent.name "Content Class"
      FunkyContent.name.should == "Content Class"
    end

    should "3. be settable using =" do
      FunkyContent.name = "Content Class"
      FunkyContent.name.should == "Content Class"
    end

    should "4. not inherit from superclass" do
      FunkyContent.name = "Custom Name"
      MoreFunkyContent.name.should == "More Funky Content"
    end
  end

  context "Field Prototypes" do
    setup do
      @content_class = Class.new(Content) do
        field :title
        field :synopsis
      end
      @content_class.field :complex, :class => Spontaneous::FieldTypes::Image, :default_value => "My default", :comment => "Use this to"
    end

    should "be creatable with just a field name" do
      @content_class.field_prototypes[:title].should be_instance_of Spontaneous::FieldPrototype
      @content_class.field_prototypes[:title].name.should == :title
    end

    should "be listable" do
      @content_class.field_names.should == [:title, :synopsis, :complex]
    end

    context "default values" do
      setup do
        @prototype = @content_class.field_prototypes[:title]
      end

      should "default to basic string class" do
        @prototype.field_class.should == Spontaneous::FieldTypes::Text
      end

      should "default to a value of ''" do
        @prototype.default_value.should == ""
      end
    end

    context "option parsing" do
      setup do
        @prototype = @content_class.field_prototypes[:complex]
      end

      should "parse field class" do
        @prototype.field_class.should == Spontaneous::FieldTypes::Image
      end

      should "parse default value" do
        @prototype.default_value.should == "My default"
      end

      should "parse ui comment" do
        @prototype.comment.should == "Use this to"
      end
    end

    context "sub-classes" do
      setup do
        @subclass = Class.new(@content_class) do
          field :child_field
        end
        @subsubclass = Class.new(@subclass) do
          field :distant_relation
        end
      end

      should "inherit super class's field prototypes" do
        @subclass.field_names.should == [:title, :synopsis, :complex, :child_field]
        @subsubclass.field_names.should == [:title, :synopsis, :complex, :child_field, :distant_relation]
      end

      should "deal intelligently with manual setting of field order" do
        @reordered_class = Class.new(@subsubclass) do
          field_order :child_field, :complex
        end
        @reordered_class.field_names.should == [:child_field, :complex, :title, :synopsis, :distant_relation]
      end
    end
  end
end
