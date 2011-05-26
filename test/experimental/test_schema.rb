# encoding: UTF-8

require 'test_helper'


class SchemaTest < MiniTest::Spec
  include Spontaneous

  context "Configurable names" do
    setup do
      class ::FunkyContent < Content; end
      class ::MoreFunkyContent < FunkyContent; end
      class ::ABCDifficultName < Content; end

      class ::CustomName < ABCDifficultName
        title "Some Name"
      end
    end

    teardown do
      [:FunkyContent, :MoreFunkyContent, :ABCDifficultName, :CustomName].each do |klass|
        Object.send(:remove_const, klass)
      end
    end

    should "default to generated version" do
      FunkyContent.default_title.should == "Funky Content"
      FunkyContent.title.should == "Funky Content"
      MoreFunkyContent.title.should == "More Funky Content"
      ABCDifficultName.default_title.should == "ABC Difficult Name"
      ABCDifficultName.title.should == "ABC Difficult Name"
    end

    should "be settable" do
      CustomName.title.should == "Some Name"
      FunkyContent.title "Content Class"
      FunkyContent.title.should == "Content Class"
    end

    should "be settable using =" do
      FunkyContent.title = "Content Class"
      FunkyContent.title.should == "Content Class"
    end

    should "not inherit from superclass" do
      FunkyContent.title = "Custom Name"
      MoreFunkyContent.title.should == "More Funky Content"
    end
  end

  context "Schema UIDs" do
    setup do
      Spontaneous.schema_map = File.expand_path('../../fixtures/schema/schema.yml', __FILE__)
      class SchemaClass < Page
        field :description
        style :simple
        layout :clean
        box :posts
      end
      @instance = SchemaClass.new
    end

    teardown do
      SchemaTest.send(:remove_const, :SchemaClass) rescue nil
    end

    should "be 12 characters long" do
      Schema::UID.generate.to_s.length.should == 12
    end

    should "be unique" do
      ids = (0..10000).map { Schema::UID.generate }
      ids.uniq.length.should == ids.length
    end

    should "be comparable" do
      uid1 = Schema::UID.new("aaaaaaaaaaaa")
      uid2 = Schema::UID.new("aaaaaaaaaaaa")
      uid3 = Schema::UID.new("bbbbbbbbbbbb")
      uid1.should == uid2
      uid1.should_not == uid3
    end

    should "be readable by content classes" do
      SchemaClass.schema_id.should == "xxxxxxxxxxxx"
    end

    should "be readable by fields" do
      @instance.fields[:description].schema_id.should == "ffffffffffff"
    end

    should "be readable by boxes" do
      @instance.boxes[:posts].schema_id.should == "bbbbbbbbbbbb"
    end

    should "be readable by styles" do
      @instance.styles[:simple].schema_id.should == "ssssssssssss"
    end

    should "be readable by layouts" do
      @instance.layout.name.should == :clean
      @instance.layout.schema_id.should == "llllllllllll"
    end
  end
  context "schema verification" do
    setup do
      Spontaneous.schema_map = File.expand_path('../../fixtures/schema/before.yml', __FILE__)
      class B < Content; end
      class C < Content; end
      class D < Content; end
      B.field :description
      B.field :author
      # have to use mocking because schema class list is totally fecked up
      # after running other tests
      # TODO: look into reliable, non-harmful way of clearing out the schema state
      #       between tests
      Schema.stubs(:content_classes).returns([B, C, D])
      Schema.classes.should == [B, C, D]
      B.schema_id.should == "bbbbbbbbbbbb"
      C.schema_id.should == "cccccccccccc"
      D.schema_id.should == "dddddddddddd"
    end

    teardown do
      SchemaTest.send(:remove_const, :B) rescue nil
      SchemaTest.send(:remove_const, :C) rescue nil
      SchemaTest.send(:remove_const, :D) rescue nil
      SchemaTest.send(:remove_const, :E) rescue nil
      SchemaTest.send(:remove_const, :F) rescue nil
    end

    should "detect addition of classes" do
      class E < Content; end
      Schema.stubs(:content_classes).returns([B, C, D, E])
      exception = nil
      begin
        Schema.validate!
        flunk("Validation should raise an exception")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_classes.should == [E]
      # need to explicitly define solution to validation error
      # Schema.expects(:generate).returns('dddddddddddd')
      # D.schema_id.should == 'dddddddddddd'
    end

    should "detect removal of classes" do
      SchemaTest.send(:remove_const, :C) rescue nil
      SchemaTest.send(:remove_const, :D) rescue nil
      Schema.stubs(:content_classes).returns([B])
      begin
        Schema.validate!
        flunk("Validation should raise an exception")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_classes.should == ["SchemaTest::C", "SchemaTest::D"]
    end

    should "detect multiple removals & additions of classes" do
      SchemaTest.send(:remove_const, :C) rescue nil
      SchemaTest.send(:remove_const, :D) rescue nil
      class E < Content; end
      class F < Content; end
      Schema.stubs(:content_classes).returns([B, E, F])
      begin
        Schema.validate!
        flunk("Validation should raise an exception if schema is modified")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_classes.should == [E, F]
      exception.removed_classes.should == ["SchemaTest::C", "SchemaTest::D"]
    end

    should "detect addition of fields" do
      B.field :name
      C.field :location
      C.field :description
      begin
        Schema.validate!
        flunk("Validation should raise an exception if new fields are added")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_fields.should == [B.field_prototypes[:name], C.field_prototypes[:location], C.field_prototypes[:description]]
    end

    should "detect removal of fields" do
      fields = [B.field_prototypes[:author]]
      B.stubs(:fields).returns(fields)
      begin
        Schema.validate!
        flunk("Validation should raise an exception if fields are removed")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_fields.should == ["description"]
    end

    should "detect addition of boxes"
    should "detect removal of boxes"
    should "detect addition of styles"
    should "detect removal of styles"
    should "detect addition of layouts"
    should "detect removal of layouts"

    should "detect addition of fields to box types"
    should "detect removal of fields from box types"
    should "detect addition of styles to box types"
    should "detect removal of styles from box types"

    should "detect addition of styles to anonymous boxes"
    should "detect removal of styles from anonymous boxes"
    should "detect addition of fields to anonymous boxes"
    should "detect removal of fields from anonymous boxes"
    should "detect addition of styles to anonymous boxes"
    should "detect removal of styles from anonymous boxes"
  end
end

