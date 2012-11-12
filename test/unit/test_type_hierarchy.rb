# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class TypeHierarchyTest < MiniTest::Spec

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Content" do
    should "have an empty supertype" do
      ::Content.supertype.should be_nil
      ::Content.supertype?.should be_false
    end
  end
  context "Schema classes" do
    setup do
      class SchemaClass < ::Piece
      end
    end
    teardown do
      self.class.send :remove_const, :SchemaClass
    end
    should "have a reference to their super type" do
      SchemaClass.supertype.should == ::Piece
    end

    should "know what file they were defined in" do
      SchemaClass.__source_file.should == File.expand_path(__FILE__)
    end
  end
end
