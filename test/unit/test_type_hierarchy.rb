# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "TypeHierarchy" do

  before do
    @site = setup_site
  end

  after do
    teardown_site
  end

  it "has an empty supertype" do
    ::Content.supertype.must_be_nil
    refute ::Content.supertype?
  end

  describe "Schema classes" do
    before do
      class SchemaClass < ::Piece
      end
    end
    after do
      Object.send :remove_const, :SchemaClass
    end
    it "have a reference to their super type" do
      SchemaClass.supertype.must_equal ::Piece
    end

    it "know what file they were defined in" do
      SchemaClass.__source_file.must_equal File.expand_path(__FILE__)
    end
  end
end
