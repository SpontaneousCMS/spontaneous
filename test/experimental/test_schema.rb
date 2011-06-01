# encoding: UTF-8

require 'test_helper'


class SchemaTest < MiniTest::Spec
  include Spontaneous

  def setup
    Spontaneous::Schema.map_class = Spontaneous::Schema::PersistentMap
    Spontaneous::Schema.reset!
  end

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

    # should "be 12 characters long" do
    #   Schema::UID.generate.to_s.length.should == 12
    # end

    should "be unique" do
      ids = (0..10000).map { Schema::UID.generate }
      ids.uniq.length.should == ids.length
    end

    # should "be comparable" do
    #   uid1 = Schema::UID.new("aaaaaaaaaaaa")
    #   uid2 = Schema::UID.new("aaaaaaaaaaaa")
    #   uid3 = Schema::UID.new("bbbbbbbbbbbb")
    #   uid1.should == uid2
    #   uid1.should_not == uid3
    # end

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

    context "lookups" do
      should "return classes" do
        Schema["xxxxxxxxxxxx"].should == SchemaClass
      end
      should "return fields" do
        Schema["ffffffffffff"].should == SchemaClass.field_prototypes[:description]
      end
      should "return boxes" do
        Schema["bbbbbbbbbbbb"].should == SchemaClass.box_prototypes[:posts]
      end
      should "return styles" do
        Schema["ssssssssssss"].should == SchemaClass.style_prototypes[:simple]
      end
      should "return layouts" do
        Schema["llllllllllll"].should == SchemaClass.layout_prototypes[:clean]
      end
    end
  end

  context "schema verification" do
    setup do
      Spontaneous.schema_map = File.expand_path('../../fixtures/schema/before.yml', __FILE__)
      class ::Page < Spontaneous::Page
        field :title
      end
      class B < ::Page; end
      class C < Content; end
      class D < Content; end
      class O < Box; end
      B.field :description
      B.field :author
      B.box :promotions do
        field :field1
        field :field2
        style :style1
        style :style2
      end
      B.box :publishers, :type => O
      B.style :inline
      B.style :outline
      B.layout :thin
      B.layout :fat

      O.field :ofield1
      O.field :ofield2
      O.style :ostyle1
      O.style :ostyle2

      # have to use mocking because schema class list is totally fecked up
      # after running other tests
      # TODO: look into reliable, non-harmful way of clearing out the schema state
      #       between tests
      # Schema.stubs(:classes).returns([B, C, D, O])
      # Schema.classes.should == [B, C, D, O]
      ::Page.schema_id.should == "tttttttttttt"
      B.schema_id.should == "bbbbbbbbbbbb"
      C.schema_id.should == "cccccccccccc"
      D.schema_id.should == "dddddddddddd"
      O.schema_id.should == "oooooooooooo"
    end

    teardown do
      Object.send(:remove_const, :Page) rescue nil
      SchemaTest.send(:remove_const, :B) rescue nil
      SchemaTest.send(:remove_const, :C) rescue nil
      SchemaTest.send(:remove_const, :D) rescue nil
      SchemaTest.send(:remove_const, :E) rescue nil
      SchemaTest.send(:remove_const, :F) rescue nil
      SchemaTest.send(:remove_const, :O) rescue nil
    end

    should "return the right schema anme for inherited box fields" do
      f = B.boxes[:publishers].instance_class.field :newfield
      B.boxes[:publishers].instance_class.fields.first.schema_name.should == "field/oooooooooooo/ofield1"
      f.schema_name.should == "field/publishers00/newfield"
    end

    should "detect addition of classes" do
      class E < Content; end
      Schema.stubs(:classes).returns([B, C, D, E])
      exception = nil
      begin
        Schema.validate_schema
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
      Schema.stubs(:classes).returns([::Page, B, O])
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_classes.map { |c| c.name }.sort.should == ["SchemaTest::C", "SchemaTest::D"]
    end

    should "detect multiple removals & additions of classes" do
      SchemaTest.send(:remove_const, :C) rescue nil
      SchemaTest.send(:remove_const, :D) rescue nil
      class E < Content; end
      class F < Content; end
      Schema.stubs(:classes).returns([::Page, B, E, F, O])
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if schema is modified")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_classes.should == [E, F]
      exception.removed_classes.map {|c| c.name}.sort.should == ["SchemaTest::C", "SchemaTest::D"]
    end

    should "detect addition of fields" do
      B.field :name
      C.field :location
      C.field :description
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new fields are added")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_fields.should == [B.field_prototypes[:name], C.field_prototypes[:location], C.field_prototypes[:description]]
    end

    should "detect removal of fields" do
      field = B.field_prototypes[:author]
      B.stubs(:field_prototypes).returns({:author => field})
      B.stubs(:fields).returns([field])
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if fields are removed")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_fields.length == 1
      exception.removed_fields[0].name.should == "description"
      exception.removed_fields[0].owner.should == SchemaTest::B
      exception.removed_fields[0].category.should == :field
    end

    should "detect addition of boxes" do
      B.box :changes
      B.box :updates
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new boxes are added")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_boxes.should == [B.boxes[:changes], B.boxes[:updates]]
    end

    should "detect removal of boxes" do
      boxes = [B.boxes[:promotions]]
      B.stubs(:boxes).returns(boxes)
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if fields are removed")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_boxes.length.should == 1
      exception.removed_boxes[0].name.should == "publishers"
      exception.removed_boxes[0].owner.should == SchemaTest::B
      exception.removed_boxes[0].category.should == :box
    end

    should "detect addition of styles" do
      B.style :fancy
      B.style :dirty
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new styles are added")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_styles.should == [B.styles.detect{ |s| s.name == :fancy }, B.styles.detect{ |s| s.name == :dirty }]
    end

    should "detect removal of styles" do
      styles = [B.styles.detect{ |s| s.name == :inline }]
      B.stubs(:styles).returns(styles)
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if styles are removed")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_styles.length.should == 1
      exception.removed_styles[0].name.should == "outline"
      exception.removed_styles[0].owner.should == SchemaTest::B
      exception.removed_styles[0].category.should == :style
    end

    should "detect addition of layouts" do
      B.layout :fancy
      B.layout :dirty
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new layouts are added")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_layouts.should == [B.layouts.detect{ |s| s.name == :fancy }, B.layouts.detect{ |s| s.name == :dirty }]
    end

    should "detect removal of layouts" do
      layouts = [B.layouts.first]
      B.stubs(:layouts).returns(layouts)
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if fields are removed")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_layouts.length.should == 1
      exception.removed_layouts[0].name.should == "fat"
      exception.removed_layouts[0].owner.should == SchemaTest::B
      exception.removed_layouts[0].category.should == :layout
    end

    should "detect addition of fields to anonymous boxes" do
      f1 = B.boxes[:publishers].instance_class.field :field3
      f2 = B.boxes[:promotions].instance_class.field :field3
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new fields are added to anonymous boxes")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_fields.should == [f1, f2]
    end

    should "detect removal of fields from anonymous boxes" do
      # f1 = B.boxes[:promotions].instance_class.field_prototypes[:field1]
      f2 = B.boxes[:promotions].instance_class.field_prototypes[:field2]
      B.boxes[:promotions].instance_class.stubs(:field_prototypes).returns({:field2 => f2})
      B.boxes[:promotions].instance_class.stubs(:fields).returns([f2])
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if fields are removed from anonymous boxes")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_fields.length.should == 1
      exception.removed_fields[0].name.should == "field1"
      exception.removed_fields[0].owner.instance_class.should == SchemaTest::B.boxes[:promotions].instance_class
      exception.removed_fields[0].category.should == :field
    end

    should "detect addition of fields to box types" do
      O.field :name
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new fields are added to boxes")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_fields.should == [O.field_prototypes[:name]]
    end

    # should "detect removal of fields from box types" do
    #   skip "stubbing is messing up the field hierarchy in weird ways"
    #   fields = [O.field_prototypes[:ofield1]]
    #   O.stubs(:fields).returns(fields)
    #   begin
    #     Schema.validate_schema
    #     flunk("Validation should raise an exception if fields are removed")
    #   rescue Spontaneous::SchemaModificationError => e
    #     exception = e
    #   end
    #   exception.removed_fields.length == 1
    #   exception.removed_fields[0].name.should == "ofield2"
    #   exception.removed_fields[0].owner.should == SchemaTest::O
    #   exception.removed_fields[0].category.should == :field
    # end

    should "detect addition of styles to box types"
    should "detect removal of styles from box types"

    should "detect addition of styles to anonymous boxes" do
      s1 = B.boxes[:publishers].instance_class.style :style3
      s2 = B.boxes[:promotions].instance_class.style :style3
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if new fields are added to anonymous boxes")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.added_styles.should == [s1, s2]
    end

    should "detect removal of styles from anonymous boxes" do
      styles = [B.boxes[:promotions].instance_class.styles.first]
      B.boxes[:promotions].instance_class.stubs(:styles).returns(styles)
      begin
        Schema.validate_schema
        flunk("Validation should raise an exception if styles are removed")
      rescue Spontaneous::SchemaModificationError => e
        exception = e
      end
      exception.removed_styles.length.should == 1
      exception.removed_styles[0].name.should == "style2"
      exception.removed_styles[0].owner.instance_class.should == SchemaTest::B.boxes[:promotions].instance_class
      exception.removed_styles[0].category.should == :style
    end
  end
end

