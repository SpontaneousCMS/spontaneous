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
      class C < Content; end
      class D < Content; end
      Schema.classes.should == [C, D]
      C.schema_id.should == "cccccccccccc"
      D.schema_id.should == "dddddddddddd"
    end

    teardown do
      SchemaTest.send(:remove_const, :C) rescue nil
      SchemaTest.send(:remove_const, :D) rescue nil
      SchemaTest.send(:remove_const, :E) rescue nil
    end

    should "detect addition of classes" do
      class E < Content; end
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
      SchemaTest.send(:remove_const, :D) rescue nil
      Schema.stubs(:classes).returns([C])
      begin
        Schema.validate!
        flunk("Validation should raise an exception")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_classes.should == ["SchemaTest::D"]
    end
    should "detect addition of fields"
    should "detect removal of fields"
    should "detect addition of boxes"
    should "detect removal of boxes"
    should "detect addition of styles"
    should "detect removal of styles"
    should "detect addition of layouts"
    should "detect removal of layouts"
  end
end

