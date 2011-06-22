# encoding: UTF-8

require 'test_helper'


class SchemaTest < MiniTest::Spec
  include Spontaneous

  UID = Spontaneous::Schema::UID

  # declare these early so that Piece & Page get loaded
  # and are then cleared early by the Schema.reset! call
  class X < Spontaneous::Piece; end
  class Y < Spontaneous::Page; end
  def setup
    Spontaneous::Schema.schema_loader_class = Spontaneous::Schema::PersistentMap
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

  context "Persistent maps" do
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

      should "be singletons" do
        a = UID["xxxxxxxxxxxx"]
        b = UID["xxxxxxxxxxxx"]
        c = UID["ffffffffffff"]
        a.object_id.should == b.object_id
        a.should == b
        c.object_id.should_not == b.object_id
        c.should_not == b
      end

      should "not be creatable" do
        lambda { UID.new('sadf') }.must_raise(NoMethodError)
      end

      should "return nil if passed nil" do
        UID[nil].should be_nil
      end

      should "return nil if passed an empty string" do
        UID[""].should be_nil
      end

      should "return the same UID if passed one" do
        a = UID["xxxxxxxxxxxx"]
        UID[a].should == a
      end

      should "test as equal to its string representation" do
        UID["llllllllllll"].should == "llllllllllll"
      end

      should "be readable by content classes" do
        SchemaClass.schema_id.should == UID["xxxxxxxxxxxx"]
      end

      should "be readable by fields" do
        @instance.fields[:description].schema_id.should == UID["ffffffffffff"]
      end

      should "be readable by boxes" do
        @instance.boxes[:posts].schema_id.should == UID["bbbbbbbbbbbb"]
      end

      should "be readable by styles" do
        @instance.styles[:simple].schema_id.should == UID["ssssssssssss"]
      end

      should "be readable by layouts" do
        @instance.layout.name.should == :clean
        @instance.layout.schema_id.should == UID["llllllllllll"]
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
        ::Page.schema_id.should == UID["tttttttttttt"]
        B.schema_id.should == UID["bbbbbbbbbbbb"]
        C.schema_id.should == UID["cccccccccccc"]
        D.schema_id.should == UID["dddddddddddd"]
        O.schema_id.should == UID["oooooooooooo"]
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
        assert_same_elements exception.added_fields, [f2, f1]
      end

      should "detect removal of fields from anonymous boxes" do
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
        assert_same_elements exception.added_styles, [s2, s1]
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
  context "Transient (testing) maps" do
    setup do
      Spontaneous::Schema.schema_loader_class = Spontaneous::Schema::TransientMap
      Spontaneous::Schema.reset!
      class V < Spontaneous::Piece; end
      class W < Spontaneous::Piece; end
    end
    teardown do
      self.class.send(:remove_const, :V)
      self.class.send(:remove_const, :W)
    end

    should "create uids on demand" do
      V.schema_id.should_not be_nil
      W.schema_id.should_not be_nil
      V.schema_id.should_not == W.schema_id
    end

    should "return consistent ids within a session" do
      a = V.schema_id
      b = V.schema_id
      a.should equal?(b)
    end

    should "return UID objects" do
      V.schema_id.must_be_instance_of(Spontaneous::Schema::UID)
    end
  end

  context "Map writing" do
    context "Non-existant maps" do
      setup do
        S::Schema.reset!
        @map_file = File.expand_path('../../../tmp/schema.yml', __FILE__)
        ::File.exists?(@map_file).should be_false
        Spontaneous.schema_map = @map_file
        class ::A < Spontaneous::Page
          field :title
          field :introduction
          layout :sparse
          box :posts do
            field :description
          end
        end
        class ::B < Spontaneous::Piece
          field :location
          style :daring
        end
      end
      teardown do
        Object.send(:remove_const, :A) rescue nil
        Object.send(:remove_const, :B) rescue nil
        FileUtils.rm(@map_file) if ::File.exists?(@map_file)
      end
      should "get created with verification" do
        S::Schema.validate!
        classes = [ ::A, ::B]
        # would like to do all of this using mocks, but don't know how to do that
        # without fecking up the whole schema id creation process
        expected = Hash[ classes.map { |klass| [ klass.schema_id.to_s, klass.schema_name ] } ]
        expected.merge!({
          A.field_prototypes[:title].schema_id.to_s => A.field_prototypes[:title].schema_name,
          A.field_prototypes[:introduction].schema_id.to_s => A.field_prototypes[:introduction].schema_name,
          A.layout_prototypes[:sparse].schema_id.to_s => A.layout_prototypes[:sparse].schema_name,
          A.boxes[:posts].schema_id.to_s => A.boxes[:posts].schema_name,
          A.boxes[:posts].field_prototypes[:description].schema_id.to_s => A.boxes[:posts].field_prototypes[:description].schema_name,
          B.field_prototypes[:location].schema_id.to_s => B.field_prototypes[:location].schema_name,
          B.style_prototypes[:daring].schema_id.to_s => B.style_prototypes[:daring].schema_name,
        })
        File.exists?(@map_file).should be_true
        YAML.load_file(@map_file).should == expected
      end
    end
    context "change resolution" do
      setup do
        S::Schema.reset!
        @map_file = File.expand_path('../../../tmp/schema.yml', __FILE__)
        FileUtils.mkdir_p(File.dirname(@map_file))
        FileUtils.cp(File.expand_path('../../fixtures/schema/resolvable.yml', __FILE__), @map_file)
        Spontaneous.schema_map = @map_file
        class ::A < Spontaneous::Page
          field :title
          field :introduction
          layout :sparse
          box :posts do
            field :description
          end
        end
        class ::B < Spontaneous::Piece
          field :location
          field :duration
          style :daring
        end
        S::Schema.validate!
        A.schema_id.should == S::Schema::UID["qLcxinA008"]
      end

      teardown do
        Object.send(:remove_const, :A) rescue nil
        Object.send(:remove_const, :B) rescue nil
        Object.send(:remove_const, :X) rescue nil
        Object.send(:remove_const, :Y) rescue nil
        S::Content.delete
        FileUtils.rm(@map_file) if ::File.exists?(@map_file)
      end

      should "be done automatically if only additions are found" do
        A.field :moose
        class ::X < ::A
          field :wild
          box :monkeys do
            field :banana
          end
          layout :rich
        end
        class ::Y < ::B
          style :risky
        end
        S::Schema.validate!
        ::X.schema_id.should_not be_nil
        ::Y.schema_id.should_not be_nil
        ::A.field_prototypes[:moose].schema_id.should_not be_nil

        m = YAML.load_file(@map_file)
        m[::A.field_prototypes[:moose].schema_id.to_s].should == ::A.field_prototypes[:moose].schema_name
        m[::X.schema_id.to_s].should == ::X.schema_name
        m[::Y.schema_id.to_s].should == ::Y.schema_name
        m[::X.field_prototypes[:wild].schema_id.to_s].should == ::X.field_prototypes[:wild].schema_name
        m[::X.boxes[:monkeys].schema_id.to_s].should == ::X.boxes[:monkeys].schema_name
        m[::X.boxes[:monkeys].field_prototypes[:banana].schema_id.to_s].should == ::X.boxes[:monkeys].field_prototypes[:banana].schema_name
        m[::X.layout_prototypes[:rich].schema_id.to_s].should == ::X.layout_prototypes[:rich].schema_name
      end


      should "be done automatically if only classes have been removed" do
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S::Schema.stubs(:classes).returns([::A])
        S::Schema.reload!
        S::Schema.validate!
        m = YAML.load_file(@map_file)
        m.key?(uid).should be_false
      end

      should "be done automatically if only boxes have been removed" do
        uid = A.boxes[:posts].schema_id.to_s
        A.stubs(:boxes).returns([])
        S::Schema.stubs(:classes).returns([A, B])
        S::Schema.reload!
        S::Schema.validate!
        m = YAML.load_file(@map_file)
        m.key?(uid).should be_false
      end

      should "be done automatically if only fields have been removed" do
        f1 = A.field_prototypes[:title]
        uid = f1.schema_id.to_s
        f2 = A.field_prototypes[:introduction]
        A.stubs(:field_prototypes).returns({:introduction => f2})
        A.stubs(:fields).returns([f2])
        S::Schema.reload!
        S::Schema.validate!
        m = YAML.load_file(@map_file)
        m.key?(uid).should be_false
      end

      should "be done automatically in presence of independent addition inside type and of type" do
        A.field :moose
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S::Schema.stubs(:classes).returns([::A])
        S::Schema.reload!
        S::Schema.validate!
        ::A.field_prototypes[:moose].schema_id.should_not be_nil

        m = YAML.load_file(@map_file)
        m[::A.field_prototypes[:moose].schema_id.to_s].should == ::A.field_prototypes[:moose].schema_name
        m.key?(uid).should be_false
      end

      should "be done automatically in presence of independent addition & removal of fields" do
        A.field :moose
        f1 = B.field_prototypes[:location]
        uid = f1.schema_id.to_s
        f2 = B.field_prototypes[:duration]
        B.stubs(:field_prototypes).returns({:duration => f2})
        B.stubs(:fields).returns([f2])
        S::Schema.reload!
        S::Schema.validate!

        ::A.field_prototypes[:moose].schema_id.should_not be_nil

        m = YAML.load_file(@map_file)
        m[::A.field_prototypes[:moose].schema_id.to_s].should == ::A.field_prototypes[:moose].schema_name
        m.key?(uid).should be_false
      end

      should "be done automatically in presence of independent changes to boxes & fields" do
        B.field :crisis
        uid = A.boxes[:posts].schema_id.to_s
        A.stubs(:boxes).returns([])
        S::Schema.stubs(:classes).returns([A, B])
        S::Schema.reload!
        S::Schema.validate!

        ::B.field_prototypes[:crisis].schema_id.should_not be_nil
        m = YAML.load_file(@map_file)
        m.key?(uid).should be_false
      end

      should "be done automatically in presence of independent changes to boxes & fields" do
        class ::X < B; end
        uid = A.boxes[:posts].schema_id.to_s
        A.stubs(:boxes).returns([])
        B.field :crisis
        B.box :circus
        A.field :crisis
        S::Schema.stubs(:classes).returns([::A, ::B, ::X])
        S::Schema.reload!
        S::Schema.validate!

        ::A.field_prototypes[:crisis].schema_id.should_not be_nil
        m = YAML.load_file(@map_file)

        box = ::B.boxes[:circus]
        m[box.schema_id.to_s].should == box.schema_name

        field = ::A.field_prototypes[:crisis]
        m[field.schema_id.to_s].should == field.schema_name

        field = ::B.field_prototypes[:crisis]
        m[field.schema_id.to_s].should == field.schema_name

        m.key?(uid).should be_false
      end


      # sanity check
      should "still raise error in case of addition & deletion" do
        A.field :added
        f1 = A.field_prototypes[:title]
        f2 = A.field_prototypes[:added]
        uid = f1.schema_id.to_s
        f3 = A.field_prototypes[:introduction]
        A.stubs(:field_prototypes).returns({:added => f2, :introduction => f3})
        A.stubs(:fields).returns([f2, f3])
        S::Schema.reload!
        lambda { S::Schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
      end

      should "still raise error in case of addition & deletion of classes" do
        class ::X < A; end
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S::Schema.stubs(:classes).returns([::A, ::X])
        S::Schema.reload!
        lambda { S::Schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
      end

      should "delete box content when a box is removed" do
        instance = A.new
        piece1 = B.new
        piece2 = B.new
        instance.posts << piece1
        instance.posts << piece2
        instance.save
        instance = S::Content[instance.id]
        instance.posts.pieces.length.should == 2
        Content.count.should == 3
        uid = A.boxes[:posts].schema_id.to_s
        A.stubs(:boxes).returns([])
        S::Schema.stubs(:classes).returns([A, B])
        S::Schema.reload!
        S::Schema.validate!
        Content.count.should == 1
        S::Content[instance.id].should == instance
      end

      context "which isn't automatically resolvable" do
        context "with one field removed" do
          setup do
            A.field :a
            A.field :b
            @df1 = A.field_prototypes[:title]
            @af1 = A.field_prototypes[:a]
            @af2 = A.field_prototypes[:b]
            @uid = @df1.schema_id.to_s
            @f3 = A.field_prototypes[:introduction]
            A.stubs(:field_prototypes).returns({:a => @af1, :b => @af2, :introduction => @f3})
            A.stubs(:fields).returns([@af1, @af2, @f3])
            S::Schema.reload!
            begin
              S::Schema.validate!
              flunk("Validation should raise error when adding & deleting fields")
            rescue Spontaneous::SchemaModificationError => e
              @modification = e.modification
            end
          end
          should "return list of solutions for removal of one field" do
            # add :a, :b, delete :title
            # add :b, rename :title  => :a
            # add :a, rename :title  => :b
            @modification.actions.description.should =~ /field 'title'/
            @modification.actions.length.should == 3
            action = @modification.actions[0]
            action.action.should == :delete
            action.source.should == @df1.schema_id
            action.description.should =~ /delete field 'title'/i
            action = @modification.actions[1]
            action.action.should == :rename
            action.source.should == @df1.schema_id
            action.description.should =~ /rename field 'title' to 'a'/i
            action = @modification.actions[2]
            action.action.should == :rename
            action.source.should == @df1.schema_id
            action.description.should =~ /rename field 'title' to 'b'/i
          end

          should "enable fixing the problem by deleting field from schema" do
            action = @modification.actions[0]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end

            m = YAML.load_file(@map_file)
            m.key?(@uid).should be_false
          end

          should "enable fixing the problem by renaming field 'a'" do
            action = @modification.actions[1]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Renaming of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m[@uid].should == @af1.schema_name
          end

          should "enable fixing the problem by renaming field 'b'" do
            action = @modification.actions[2]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Renaming of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m[@uid].should == @af2.schema_name
          end
        end

        context "with two fields removed" do
          setup do
            A.field :a
            A.field :b
            A.field :c
            @df1 = A.field_prototypes[:title]
            @df2 = A.field_prototypes[:introduction]
            @af1 = A.field_prototypes[:a]
            @af2 = A.field_prototypes[:b]
            @af3 = A.field_prototypes[:c]
            @uid1 = @df1.schema_id.to_s
            @uid2 = @df2.schema_id.to_s
            A.stubs(:field_prototypes).returns({:a => @af1, :b => @af2, :c => @af3})
            A.stubs(:fields).returns([@af1, @af2, @af3])
            S::Schema.reload!
            begin
              S::Schema.validate!
              flunk("Validation should raise error when adding & deleting fields")
            rescue Spontaneous::SchemaModificationError => e
              @modification = e.modification
            end
          end
          should "return list of solutions" do
            # add :a, :b; delete :title, :introduction
            # rename :title  => :a, :introduction  => :b
            # rename :introduction  => :a, :title  => :b
            # add :a; delete :introduction; rename :title  => :b
            # add :a; delete :title;        rename :introduction  => :b
            # add :b; delete :introduction; rename :title  => :a
            # add :b; delete :title;        rename :introduction  => :a
            @modification.actions.description.should =~ /field 'title'/
            @modification.actions.length.should == 4
            action = @modification.actions[0]
            action.action.should == :delete
            action.source.should == @df1.schema_id
            action.description.should =~ /delete field 'title'/i
            action = @modification.actions[1]
            action.action.should == :rename
            action.source.should == @df1.schema_id
            action.description.should =~ /rename field 'title' to 'a'/i
            action = @modification.actions[2]
            action.action.should == :rename
            action.source.should == @df1.schema_id
            action.description.should =~ /rename field 'title' to 'b'/i
            action = @modification.actions[3]
            action.action.should == :rename
            action.source.should == @df1.schema_id
            action.description.should =~ /rename field 'title' to 'c'/i
          end

          should "enable fixing the problem by deleting both fields" do
            action = @modification.actions[0]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
              flunk("Deletion of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[0]

            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m.key?(@uid1).should be_false
            m.key?(@uid2).should be_false
          end

          should "enable fixing the problem by deleting one field and renaming other as 'a'" do
            action = @modification.actions[0]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
              flunk("Deletion of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[1]

            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m.key?(@uid1).should be_false
            m.key?(@uid2).should be_true
            m[@uid2].should == @af1.schema_name
          end

          should "enable fixing the problem by renaming one field as 'c' and deleting other" do
            action = @modification.actions[3]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
              flunk("Renaming of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[0]

            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m.key?(@uid1).should be_true
            m.key?(@uid2).should be_false
            m[@uid1].should == @af3.schema_name
          end
          should "enable fixing the problem by renaming one field as 'c' and renaming other as 'b'" do
            action = @modification.actions[3]
            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
              flunk("Renaming of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[2]

            S::Schema.apply_fix(action)
            begin
              S::Schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m.key?(@uid1).should be_true
            m.key?(@uid2).should be_true
            m[@uid1].should == @af3.schema_name
            m[@uid2].should == @af2.schema_name
          end
        end

      end
    end
  end
end

