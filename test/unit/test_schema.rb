require 'test_helper'



class SchemasTest < Test::Unit::TestCase
  include Spontaneous

  context "Configurable names" do
    setup do
      class FunkyContent < Content
      end
      class MoreFunkyContent < FunkyContent
      end
      class ABCDifficultName < Content
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
end
