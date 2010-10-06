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
    should "default to generated version" do
      FunkyContent.name.should == "Funky Content"
      MoreFunkyContent.name.should == "More Funky Content"
      ABCDifficultName.name.should == "ABC Difficult Name"
    end

    should "be settable" do
      FunkyContent.name = "Content Class"
      FunkyContent.name.should == "Content Class"
    end

    should "not inherit from superclass" do
      FunkyContent.name = "Custom Name"
      MoreFunkyContent.name.should == "More Funky Content"
    end
  end
end
