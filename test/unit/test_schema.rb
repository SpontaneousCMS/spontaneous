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

  context "Content fields" do
    context "prototypes" do
      setup do
        class ContentClass < Content
          field :title
        end
      end

      should "work with just a field name" do
        ContentClass.field_prototypes[:title].should be_instance_of Spontaneous::FieldPrototype
        ContentClass.field_prototypes[:title].name.should == :title
      end

      context "default values" do
        setup do
          @prototype = ContentClass.field_prototypes[:title]
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
          ContentClass.field :complex, :class => Image, :default_value => "My default", :comment => "Use this to"
          @prototype = ContentClass.field_prototypes[:complex]
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
    end
  end
end
