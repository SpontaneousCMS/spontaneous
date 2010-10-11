require 'test_helper'


class SchemasTest < Test::Unit::TestCase
  include Spontaneous

  context "Configurable names" do
    setup do
      class FunkyContent < Content; end
      class MoreFunkyContent < FunkyContent; end
      class ABCDifficultName < Content; end

      class CustomName < ABCDifficultName
        title "Some Name"
      end
    end

    should "1. default to generated version" do
      FunkyContent.default_title.should == "Funky Content"
      FunkyContent.title.should == "Funky Content"
      MoreFunkyContent.title.should == "More Funky Content"
      ABCDifficultName.default_title.should == "ABC Difficult Name"
      ABCDifficultName.title.should == "ABC Difficult Name"
    end

    should "2. be settable" do
      CustomName.title.should == "Some Name"
      FunkyContent.title "Content Class"
      FunkyContent.title.should == "Content Class"
    end

    should "3. be settable using =" do
      FunkyContent.title = "Content Class"
      FunkyContent.title.should == "Content Class"
    end

    should "4. not inherit from superclass" do
      FunkyContent.title = "Custom Name"
      MoreFunkyContent.title.should == "More Funky Content"
    end
  end

end
