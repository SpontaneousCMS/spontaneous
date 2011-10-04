# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class TypeHierarchyTest < MiniTest::Spec


  context "Content" do
    should "have an empty supertype" do
      S::Content.supertype.should be_nil
      S::Content.supertype?.should be_false
    end
  end
  context "Schema classes" do
    setup do
      class SchemaClass < Spontaneous::Piece
      end
    end
    should "have a reference to their super type" do
      SchemaClass.supertype.should == Spontaneous::Piece
    end

    should "know what file they were defined in" do
      SchemaClass.__source_file.should == File.expand_path(__FILE__)
    end
  end
end
