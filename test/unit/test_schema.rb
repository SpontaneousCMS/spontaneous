# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Schema" do
  before do
    @site = setup_site
    @site.schema_loader_class = Spontaneous::Schema::PersistentMap
    @user_levels_file = File.expand_path('../../fixtures/permissions', __FILE__) / 'config/user_levels.yml'
    S::Permissions::UserLevel.reset!
    S::Permissions::UserLevel.stubs(:level_file).returns(@user_levels_file)
  end

  after do
    teardown_site
  end

  describe "Configurable names" do
    before do
      class ::FunkyContent < Piece; end
      class ::MoreFunkyContent < FunkyContent; end
      class ::ABCDifficultName < Piece; end

      class ::CustomName < ABCDifficultName
        title "Some Name"
      end
    end

    after do
      [:FunkyContent, :MoreFunkyContent, :ABCDifficultName, :CustomName].each do |klass|
        Object.send(:remove_const, klass)
      end
    end

    it "default to generated version" do
      FunkyContent.default_title.must_equal "Funky Content"
      FunkyContent.title.must_equal "Funky Content"
      MoreFunkyContent.title.must_equal "More Funky Content"
      ABCDifficultName.default_title.must_equal "ABC Difficult Name"
      ABCDifficultName.title.must_equal "ABC Difficult Name"
    end

    it "be settable" do
      CustomName.title.must_equal "Some Name"
      FunkyContent.title "Content Class"
      FunkyContent.title.must_equal "Content Class"
    end

    it "be settable using =" do
      FunkyContent.title = "Content Class"
      FunkyContent.title.must_equal "Content Class"
    end

    it "not inherit from superclass" do
      FunkyContent.title = "Custom Name"
      MoreFunkyContent.title.must_equal "More Funky Content"
    end
  end

  describe "Persistent maps" do
    describe "Schema UIDs" do
      before do
        @site.schema.schema_map_file = File.expand_path('../../fixtures/schema/schema.yml', __FILE__)
        class SchemaClass < Page
          field :description
          style :simple
          layout :clean
          box :posts
        end
        # force loading of map
        @site.schema.map
        @instance = SchemaClass.new
        @uids = @site.schema.uids
      end

      after do
        Object.send(:remove_const, :SchemaClass) rescue nil
      end

      it "be unique" do
        ids = (0..10000).map { S::Schema::UIDMap.generate }
        ids.uniq.length.must_equal ids.length
      end


      it "be singletons" do
        a = @uids["xxxxxxxxxxxx"]
        b = @uids["xxxxxxxxxxxx"]
        c = @uids["ffffffffffff"]
        a.object_id.must_equal b.object_id
        a.must_equal b
        c.object_id.wont_equal b.object_id
        c.wont_equal b
      end

      it "return nil if passed nil" do
        @uids[nil].must_be_nil
      end

      it "return nil if passed an empty string" do
        @uids[""].must_be_nil
      end

      it "return the same UID if passed one" do
        a = @uids["xxxxxxxxxxxx"]
        @uids[a].must_be_same_as a
      end

      it "test as equal to its string representation" do
        "llllllllllll".must_equal @uids["llllllllllll"]
      end

      it "test as eql? if they have the same id" do
        a = @uids["llllllllllll"]
        b = a.dup
        assert a.eql?(b), "Identical IDs should pass eql? test"
      end

      it "should be serializable to JSON" do
        a = SchemaClass.schema_id
        json = Spontaneous::JSON.encode a
        json.must_equal '"xxxxxxxxxxxx"'
      end

      it "be readable by content classes" do
        SchemaClass.schema_id.must_equal @uids["xxxxxxxxxxxx"]
      end

      it "be readable by fields" do
        @instance.fields[:description].schema_id.must_equal @uids["ffffffffffff"]
      end

      it "be readable by boxes" do
        @instance.boxes[:posts].schema_id.must_equal @uids["bbbbbbbbbbbb"]
      end

      it "be readable by styles" do
        @instance.styles[:simple].schema_id.must_equal @uids["ssssssssssss"]
      end

      it "be readable by layouts" do
        @instance.layout.name.must_equal :clean
        @instance.layout.schema_id.must_equal @uids["llllllllllll"]
      end

      it "should encode to JSON" do
        @uids["llllllllllll"].to_json.must_equal '"llllllllllll"'
      end

      describe "lookups" do
        it "return classes" do
          @site.schema.to_class("xxxxxxxxxxxx").must_equal SchemaClass
        end
        it "return fields" do
          @site.schema.to_class("ffffffffffff").must_equal SchemaClass.field_prototypes[:description]
        end
        it "return boxes" do
          @site.schema.to_class("bbbbbbbbbbbb").must_equal SchemaClass.box_prototypes[:posts]
        end
        it "return styles" do
          @site.schema.to_class("ssssssssssss").must_equal SchemaClass.style_prototypes[:simple]
        end
        it "return layouts" do
          @site.schema.to_class("llllllllllll").must_equal SchemaClass.layout_prototypes[:clean]
        end
      end

    end

    describe "schema verification" do
      before do
        @site.schema.schema_map_file = File.expand_path('../../fixtures/schema/before.yml', __FILE__)
        Page.field :title
        class B < Page; end
        class C < Piece; end
        class D < Piece; end
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

        @site.schema.map
        @uids = @site.schema.uids
        ::Page.schema_id.must_equal @uids["tttttttttttt"]
        B.schema_id.must_equal @uids["bbbbbbbbbbbb"]
        C.schema_id.must_equal @uids["cccccccccccc"]
        D.schema_id.must_equal @uids["dddddddddddd"]
        O.schema_id.must_equal @uids["oooooooooooo"]
      end

      after do
        Object.send(:remove_const, :B) rescue nil
        Object.send(:remove_const, :C) rescue nil
        Object.send(:remove_const, :D) rescue nil
        Object.send(:remove_const, :E) rescue nil
        Object.send(:remove_const, :F) rescue nil
        Object.send(:remove_const, :O) rescue nil
      end

      it "return the right schema anme for inherited box fields" do
        f = B.boxes[:publishers].instance_class.field :newfield
        B.boxes[:publishers].instance_class.fields.first.schema_name.must_equal "field/oooooooooooo/ofield1"
        f.schema_name.must_equal "field/publishers00/newfield"
      end

      it "detect addition of classes" do
        class E < ::Piece; end
        @site.schema.stubs(:classes).returns([B, C, D, E])
        exception = nil
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_classes.must_equal [E]
        # need to explicitly define solution to validation error
        # Schema.expects(:generate).returns('dddddddddddd')
        # D.schema_id.must_equal 'dddddddddddd'
      end

      it "detect removal of classes" do
        Object.send(:remove_const, :C) rescue nil
        Object.send(:remove_const, :D) rescue nil
        @site.schema.stubs(:classes).returns([::Page, B, O])
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_classes.map { |c| c.name }.sort.must_equal ["C", "D"]
      end

      it "detect multiple removals & additions of classes" do
        Object.send(:remove_const, :C) rescue nil
        Object.send(:remove_const, :D) rescue nil
        class E < Content; end
        class F < Content; end
        @site.schema.stubs(:classes).returns([::Page, B, E, F, O])
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if schema is modified")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_classes.must_equal [E, F]
        exception.removed_classes.map {|c| c.name}.sort.must_equal ["C", "D"]
      end

      it "detect addition of fields" do
        B.field :name
        C.field :location
        C.field :description
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new fields are added")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_fields.must_equal [B.field_prototypes[:name], C.field_prototypes[:location], C.field_prototypes[:description]]
      end

      it "detect removal of fields" do
        field = B.field_prototypes[:author]
        B.stubs(:field_prototypes).returns({:author => field})
        B.stubs(:fields).returns([field])
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if fields are removed")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_fields.length == 1
        exception.removed_fields[0].name.must_equal "description"
        exception.removed_fields[0].owner.must_equal B
        exception.removed_fields[0].category.must_equal :field
      end

      it "detect addition of boxes" do
        B.box :changes
        B.box :updates
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new boxes are added")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_boxes.must_equal [B.boxes[:changes], B.boxes[:updates]]
      end

      it "detect removal of boxes" do
        boxes = S::Collections::PrototypeSet.new
        boxes[:promotions] = B.boxes[:promotions]

        B.stubs(:box_prototypes).returns(boxes)
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if fields are removed")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_boxes.length.must_equal 1
        exception.removed_boxes[0].name.must_equal "publishers"
        exception.removed_boxes[0].owner.must_equal B
        exception.removed_boxes[0].category.must_equal :box
      end

      it "detect addition of styles" do
        B.style :fancy
        B.style :dirty
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new styles are added")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_styles.must_equal [B.styles.detect{ |s| s.name == :fancy }, B.styles.detect{ |s| s.name == :dirty }]
      end

      it "detect removal of styles" do
        style = B.styles[:inline]
        B.styles.expects(:order).returns([:inline])
        B.styles.stubs(:[]).with(:inline).returns(style)
        B.styles.stubs(:[]).with(:outline).returns(nil)
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if styles are removed")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_styles.length.must_equal 1
        exception.removed_styles[0].name.must_equal "outline"
        exception.removed_styles[0].owner.must_equal B
        exception.removed_styles[0].category.must_equal :style
      end

      it "detect addition of layouts" do
        B.layout :fancy
        B.layout :dirty
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new layouts are added")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_layouts.must_equal [B.layouts.detect{ |s| s.name == :fancy }, B.layouts.detect{ |s| s.name == :dirty }]
      end

      it "detect removal of layouts" do
        layout = B.layouts[:thin]
        B.layouts.expects(:order).returns([:thin])
        B.layouts.stubs(:[]).with(:thin).returns(layout)
        B.layouts.stubs(:[]).with(:fat).returns(nil)
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if fields are removed")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_layouts.length.must_equal 1
        exception.removed_layouts[0].name.must_equal "fat"
        exception.removed_layouts[0].owner.must_equal B
        exception.removed_layouts[0].category.must_equal :layout
      end

      it "detect addition of fields to anonymous boxes" do
        f1 = B.boxes[:publishers].instance_class.field :field3
        f2 = B.boxes[:promotions].instance_class.field :field3
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new fields are added to anonymous boxes")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        assert_has_elements exception.added_fields, [f2, f1]
      end

      it "detect removal of fields from anonymous boxes" do
        f2 = B.boxes[:promotions].instance_class.field_prototypes[:field2]
        B.boxes[:promotions].instance_class.stubs(:field_prototypes).returns({:field2 => f2})
        B.boxes[:promotions].instance_class.stubs(:fields).returns([f2])
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if fields are removed from anonymous boxes")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_fields.length.must_equal 1
        exception.removed_fields[0].name.must_equal "field1"
        exception.removed_fields[0].owner.instance_class.must_equal B.boxes[:promotions].instance_class
        exception.removed_fields[0].category.must_equal :field
      end

      it "detect addition of fields to box types" do
        O.field :name
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new fields are added to boxes")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.added_fields.must_equal [O.field_prototypes[:name]]
      end

      # it "detect removal of fields from box types" do
      #   skip "stubbing is messing up the field hierarchy in weird ways"
      #   fields = [O.field_prototypes[:ofield1]]
      #   O.stubs(:fields).returns(fields)
      #   begin
      #     @site.schema.validate_schema
      #     flunk("Validation should raise an exception if fields are removed")
      #   rescue Spontaneous::SchemaModificationError => e
      #     exception = e
      #   end
      #   exception.removed_fields.length == 1
      #   exception.removed_fields[0].name.must_equal "ofield2"
      #   exception.removed_fields[0].owner.must_equal O
      #   exception.removed_fields[0].category.must_equal :field
      # end

      it "detect addition of styles to box types"
      it "detect removal of styles from box types"

      it "detect addition of styles to anonymous boxes" do
        s1 = B.boxes[:publishers].instance_class.style :style3
        s2 = B.boxes[:promotions].instance_class.style :style3
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if new fields are added to anonymous boxes")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        assert_has_elements exception.added_styles, [s2, s1]
      end

      it "detect removal of styles from anonymous boxes" do
        klass = B.boxes[:promotions].instance_class
        style = klass.styles.first
        klass.styles.expects(:order).returns([style.name])
        klass.styles.stubs(:[]).with(style.name).returns(style)
        klass.styles.stubs(:[]).with(:style2).returns(nil)
        begin
          @site.schema.validate_schema
          flunk("Validation should raise an exception if styles are removed")
        rescue Spontaneous::SchemaModificationError => e
          exception = e
        end
        exception.removed_styles.length.must_equal 1
        exception.removed_styles[0].name.must_equal "style2"
        exception.removed_styles[0].owner.instance_class.must_equal B.boxes[:promotions].instance_class
        exception.removed_styles[0].category.must_equal :style
      end
    end
  end

  describe "Transient (testing) maps" do
    before do
      @site.schema.schema_loader_class = Spontaneous::Schema::TransientMap
      class V < ::Piece; end
      class W < ::Piece; end
    end
    after do
      Object.send(:remove_const, :V)
      Object.send(:remove_const, :W)
    end

    it "create uids on demand" do
      V.schema_id.wont_be_nil
      W.schema_id.wont_be_nil
      V.schema_id.wont_equal W.schema_id
    end

    it "return consistent ids within a session" do
      a = V.schema_id
      b = V.schema_id
      a.must_be_same_as(b)
    end

    it "return UID objects" do
      V.schema_id.must_be_instance_of(Spontaneous::Schema::UID)
    end

    describe "for inherited boxes" do
      before do
        class ::A < ::Piece
          box :a
        end
        class ::B < ::A
          box :a
        end
        class ::C < ::B
          box :a
        end
      end
      after do
        Object.send(:remove_const, :A) rescue nil
        Object.send(:remove_const, :B) rescue nil
        Object.send(:remove_const, :C) rescue nil
      end
      it "be the same as the box in the supertype" do
        B.boxes[:a].schema_id.must_equal A.boxes[:a].schema_id
        C.boxes[:a].schema_id.must_equal A.boxes[:a].schema_id
        B.boxes[:a].instance_class.schema_id.must_equal A.boxes[:a].instance_class.schema_id
        C.boxes[:a].instance_class.schema_id.must_equal A.boxes[:a].instance_class.schema_id
      end
    end
  end

  describe "Schema groups" do
    before do
      class ::A < ::Page
        group :a, :b, :c
        box :cgroup do
          allow_group :c
        end
      end
      class ::B < ::Piece
        group :b, :c
        style :fish
        style :frog

        box :agroup do
          allow_groups :a, :c
        end
      end
      class ::C < ::Piece
        group :c

        box :bgroup do
          allow_group :b, :style => "fish"
        end
        box :cgroup do
          allow_group :c, :level => :root
        end
      end
    end

    after do
      Object.send(:remove_const, :A) rescue nil
      Object.send(:remove_const, :B) rescue nil
      Object.send(:remove_const, :C) rescue nil
    end

    it "let boxes allow a list of content types" do
      A.boxes.cgroup.allowed_types(nil).must_equal [A, B, C]
      C.boxes.bgroup.allowed_types(nil).must_equal [A, B]
      C.boxes.cgroup.allowed_types(nil).must_equal [A, B, C]
      B.boxes.agroup.allowed_types(nil).must_equal [A, B, C]
    end

    it "apply the options to all the included classes" do
      user = mock()
      S::Permissions.stubs(:has_level?).with(user, S::Permissions::UserLevel.editor).returns(true)
      S::Permissions.stubs(:has_level?).with(user, S::Permissions::UserLevel.root).returns(true)
      C.boxes.cgroup.allowed_types(user).must_equal [A, B, C]
      S::Permissions.stubs(:has_level?).with(user, S::Permissions::UserLevel.editor).returns(true)
      S::Permissions.stubs(:has_level?).with(user, S::Permissions::UserLevel.root).returns(false)
      C.boxes.cgroup.allowed_types(user).must_equal []
      A.boxes.cgroup.allowed_types(user).must_equal [A, B, C]
    end

    it "allow for configuring styles" do
      c = C.new
      b = B.new
      styles =  c.bgroup.available_styles(b)
      styles.length.must_equal 1
      styles.first.name.must_equal :fish
    end

    it "ignores suggested styles if they don't exist for the type" do
      c = C.new
      a = A.new
      styles =  c.bgroup.available_styles(a)
      styles.length.must_equal 0
    end

    it "reload correctly" do
      FileUtils.mkdir(@site.root / "config")
      @site.schema.write_schema
      @site.schema.delete(::B)
      Object.send(:remove_const, :B)

      class ::B < ::Piece
        group :b
        style :fish
        style :frog

        box :agroup do
          allow_groups :a, :c
        end
      end

      @site.schema.validate!

      A.boxes.cgroup.allowed_types(nil).must_equal [A, C]
      C.boxes.bgroup.allowed_types(nil).must_equal [A, B]
    end

    it "exports the list of allowed types to the ui" do
      B.boxes.agroup.export(nil)[:allowed_types].must_equal [{type:"A"}, {type:"B"}, {type:"C"}]
    end
  end


  describe "Map writing" do
    describe "Non-existant maps" do
      def expected_schema
        classes = @site.schema.classes#[ Content::Page, Page, Content::Piece, Piece, ::A, ::B]
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
        expected
      end

      before do
        @map_file = File.expand_path('../../../tmp/schema.yml', __FILE__)

        ::FileUtils.rm_f(@map_file) if ::File.exists?(@map_file)

        @site.schema.schema_map_file = @map_file
        class ::A < ::Page
          field :title
          field :introduction
          layout :sparse
          box :posts do
            field :description
          end
        end
        class ::B < ::Piece
          field :location
          style :daring
        end
      end

      after do
        Object.send(:remove_const, :A) rescue nil
        Object.send(:remove_const, :B) rescue nil
        FileUtils.rm(@map_file) if ::File.exists?(@map_file)
      end

      it "get created with verification" do
        S.schema.validate!
        assert File.exists?(@map_file)
        YAML.load_file(@map_file).must_equal expected_schema
      end

      # Having the generator create an empty config/schema.yml is a useful way of
      # identifying a spontaneous site (for use by bin/spot)
      it "get overwritten if invalid or empty" do
        File.open(@map_file, "w") do |f|
          f.write("# schema")
        end
        assert File.exists?(@map_file)
        refute S.schema.map.valid?
        S.schema.validate!
        assert S.schema.map.valid?
        YAML.load_file(@map_file).must_equal expected_schema
      end
    end

    describe "change resolution" do
      before do
        @map_file = File.expand_path('../../../tmp/schema.yml', __FILE__)
        FileUtils.mkdir_p(File.dirname(@map_file))
        FileUtils.cp(File.expand_path('../../fixtures/schema/resolvable.yml', __FILE__), @map_file)
        @site.schema.schema_map_file = @map_file
        class ::A < ::Page
          field :title
          field :introduction
          layout :sparse
          box :posts do
            field :description
          end
        end
        class ::B < ::Piece
          field :location
          field :duration
          style :daring
        end
        @site.schema.validate!
        A.schema_id.must_equal S.schema.uids["qLcxinA008"]
      end

      describe "renamed boxes" do
        before do
          S.schema.delete(::A)
          Object.send :remove_const, :A
          class ::A < ::Page
            field :title
            field :introduction
            layout :sparse
            box :renamed do
              field :description
            end
          end
        end
        it "raise a validation exception" do
          lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
        end
        describe "modification exception" do
          before do
            begin
              S.schema.validate!
            rescue Spontaneous::SchemaModificationError => e
              @exception = e
              @modification = e.modification
            end
          end

          it "not be resolvable" do
            refute @modification.resolvable?
          end
          it "have one added & one removed box"do
            @modification.added_boxes.length.must_equal 1
            @modification.added_boxes.first.name.must_equal :renamed
            @modification.removed_boxes.length.must_equal 1
            @modification.removed_boxes.first.name.must_equal "posts"
          end
        end
      end

      after do
        Object.send(:remove_const, :A) rescue nil
        Object.send(:remove_const, :B) rescue nil
        Object.send(:remove_const, :X) rescue nil
        Object.send(:remove_const, :Y) rescue nil
        ::Content.delete
        FileUtils.rm(@map_file) if ::File.exists?(@map_file) rescue nil
      end

      it "be done automatically if only additions are found" do
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
        S.schema.validate!
        ::X.schema_id.wont_be_nil
        ::Y.schema_id.wont_be_nil
        ::A.field_prototypes[:moose].schema_id.wont_be_nil

        m = YAML.load_file(@map_file)
        m[::A.field_prototypes[:moose].schema_id.to_s].must_equal ::A.field_prototypes[:moose].schema_name
        m[::X.schema_id.to_s].must_equal ::X.schema_name
        m[::Y.schema_id.to_s].must_equal ::Y.schema_name
        m[::X.field_prototypes[:wild].schema_id.to_s].must_equal ::X.field_prototypes[:wild].schema_name
        m[::X.boxes[:monkeys].schema_id.to_s].must_equal ::X.boxes[:monkeys].schema_name
        m[::X.boxes[:monkeys].field_prototypes[:banana].schema_id.to_s].must_equal ::X.boxes[:monkeys].field_prototypes[:banana].schema_name
        m[::X.layout_prototypes[:rich].schema_id.to_s].must_equal ::X.layout_prototypes[:rich].schema_name
      end



      it "be done automatically if only fields have been removed" do
        uid = A.fields[:title].schema_id.to_s
        S.schema.delete(::A)
        Object.send :remove_const, :A
        class ::A < ::Page
          field :introduction
          layout :sparse
          box(:posts) { field :description }
        end
        S.schema.reload!
        S.schema.validate!
        m = YAML.load_file(@map_file)
        refute m.key?(uid)
      end

      it "be done automatically in presence of independent addition & removal of fields" do
        A.field :moose
        f1 = B.field_prototypes[:location]
        uid = f1.schema_id.to_s
        f2 = B.field_prototypes[:duration]
        B.stubs(:field_prototypes).returns({:duration => f2})
        B.stubs(:fields).returns([f2])
        S.schema.reload!
        S.schema.validate!

        ::A.field_prototypes[:moose].schema_id.wont_be_nil

        m = YAML.load_file(@map_file)
        m[::A.field_prototypes[:moose].schema_id.to_s].must_equal ::A.field_prototypes[:moose].schema_name
        refute m.key?(uid)
      end

      # sanity check
      it "still raise error in case of addition & deletion" do
        A.field :added
        f1 = A.field_prototypes[:title]
        f2 = A.field_prototypes[:added]
        uid = f1.schema_id.to_s
        f3 = A.field_prototypes[:introduction]
        A.stubs(:field_prototypes).returns({:added => f2, :introduction => f3})
        A.stubs(:fields).returns([f2, f3])
        S.schema.reload!
        lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
      end

      it "still raise error in case of addition & deletion of classes" do
        class ::X < A; end
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S.schema.stubs(:classes).returns([::A, ::X])
        S.schema.reload!
        lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
      end

      it "raise an error if classes have been removed" do
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S.schema.stubs(:classes).returns([::A])
        S.schema.reload!

        lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
      end

      it "raise an error if boxes have been removed" do
        uid = A.boxes[:posts].schema_id.to_s
        Object.send :remove_const, :A
        class ::A < ::Page
          field :title
          field :introduction
          layout :sparse
        end
        S.schema.stubs(:classes).returns([A, B])
        S.schema.reload!
        lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
      end

      it "delete box content when a box is removed" do
        instance = A.new
        piece1 = B.new
        piece2 = B.new
        instance.posts << piece1
        instance.posts << piece2
        instance.save
        instance = Content[instance.id]
        instance.posts.contents.length.must_equal 2
        Content.count.must_equal 3
        uid = A.boxes[:posts].schema_id.to_s
        A.stubs(:box_prototypes).returns(S::Collections::PrototypeSet.new)
        S.schema.stubs(:classes).returns([A, B])
        S.schema.reload!

        begin
          S.schema.validate!
          flunk("Validation should raise error when adding & deleting fields")
        rescue Spontaneous::SchemaModificationError => e
          @modification = e.modification
        end
        action = @modification.actions.first
        S.schema.apply(action)
        Content.count.must_equal 1
        Content[instance.id].must_equal instance
      end

      it "removes associated page locks when deleting removed box content" do
        instance = A.new
        piece1 = B.new
        piece2 = B.new
        instance.posts << piece1
        instance.posts << piece2
        instance.save
        instance = Content[instance.id]
        instance.posts.contents.length.must_equal 2
        Content.count.must_equal 3
        uid = A.boxes[:posts].schema_id.to_s
        A.stubs(:box_prototypes).returns(S::Collections::PrototypeSet.new)
        S.schema.stubs(:classes).returns([A, B])
        S.schema.reload!

        lock = Spontaneous::PageLock.create(page_id: instance.page.id, content_id: instance.id, field_id: instance.title.id, description: "Update Lock")
        lock2 = Spontaneous::PageLock.create(page_id: piece2.page.id, content_id: piece2.id, field_id: piece2.location.id, description: "Update Lock")
        lock2 = Spontaneous::PageLock.create(page_id: piece2.page.id, content_id: piece2.id, field_id: piece2.location.id, description: "Update Lock")

        Spontaneous::PageLock.count.must_equal 3

        begin
          S.schema.validate!
          flunk("Validation should raise error when adding & deleting fields")
        rescue Spontaneous::SchemaModificationError => e
          @modification = e.modification
        end
        action = @modification.actions.first
        S.schema.apply(action)
        Content.count.must_equal 1
        Content[instance.id].must_equal instance
        Spontaneous::PageLock.count.must_equal 1
      end

      it "deletes type instances when a type is removed" do
        Spontaneous::State.instance.update(must_publish_all: false)
        @site.must_publish_all?.must_equal false
        B.box :pages
        A.box :pages
        # a1
        #  |- b2
        #      |- a3
        #  |- a2
        #
        # b1
        #  |- a4
        a1, a2, a3, a4 = A.create, A.create, A.create, A.create
        b1, b2, b3     = B.create, B.create, B.create
        a1.pages << b2
        a1.pages << a2
        b2.pages << a3
        b1.pages << a4
        [a1, a2, a3, a4, b1, b2, b3].each(&:save)
        Content.count.must_equal 7
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S.schema.stubs(:classes).returns([::A])
        S.schema.reload!
        begin
          S.schema.validate!
          flunk("Validation should raise error when adding & deleting fields")
        rescue Spontaneous::SchemaModificationError => e
          @modification = e.modification
        end
        action = @modification.actions.first
        S.schema.apply(action)
        # The type filtering automatically filters out any instances belonging to the deleted type
        # only a1 & a2 should be left
        Content.count.must_equal 2
        all = Content.order(:id).all
        all.map(&:class).must_equal [A, A]
        # to check that they're gone from the db i have to go a bit lower
        content = S.database[:content].all
        content.length.must_equal 2
        content.map { |c| c[:type_sid] }.must_equal [A.schema_id.to_s, A.schema_id.to_s]
        @site.must_publish_all?.must_equal true
      end

      it "deletes dependent page locks type when a type is removed" do
        Spontaneous::State.instance.update(must_publish_all: false)
        @site.must_publish_all?.must_equal false
        B.box :pages
        A.box :pages
        # a1
        #  |- b2
        #      |- a3
        #  |- a2
        #
        # b1
        #  |- a4
        a1, a2, a3, a4 = A.create, A.new, A.new, A.new
        b1, b2, b3     = B.create, B.new, B.new
        a1.pages << b2
        a1.pages << a2
        b2.pages << a3
        b1.pages << a4
        [a1, a2, a3, a4, b1, b2, b3].each(&:save)

        lock_a1 = Spontaneous::PageLock.create(content_id: a1.id)
        lock_a3 = Spontaneous::PageLock.create(content_id: a3.id)
        lock_a4 = Spontaneous::PageLock.create(content_id: a4.id)
        lock_b1 = Spontaneous::PageLock.create(content_id: b1.id)
        lock_b2 = Spontaneous::PageLock.create(content_id: b2.id)
        lock_b3 = Spontaneous::PageLock.create(content_id: b3.id)

        Spontaneous::PageLock.count.must_equal 6

        Content.count.must_equal 7
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S.schema.stubs(:classes).returns([::A])
        S.schema.reload!
        begin
          S.schema.validate!
          flunk("Validation should raise error when adding & deleting fields")
        rescue Spontaneous::SchemaModificationError => e
          @modification = e.modification
        end
        action = @modification.actions.first
        S.schema.apply(action)
        # The type filtering automatically filters out any instances belonging to the deleted type
        # only a1 & a2 should be left
        Content.count.must_equal 2
        all = Content.order(:id).all
        all.map(&:class).must_equal [A, A]
        # to check that they're gone from the db i have to go a bit lower
        content = S.database[:content].all
        content.length.must_equal 2
        content.map { |c| c[:type_sid] }.must_equal [A.schema_id.to_s, A.schema_id.to_s]
        @site.must_publish_all?.must_equal true
        Spontaneous::PageLock.count.must_equal 1
        Spontaneous::PageLock.first(content_id: a1.id).wont_be_nil
      end

      it "doesn't mark the site as 'dirty' if no instances are deleted by the change in the schema" do
        Spontaneous::State.instance.update(must_publish_all: false)
        @site.must_publish_all?.must_equal false
        A.box :pages
        # a1
        #  |- b2
        #      |- a3
        #  |- a2
        #
        # b1
        #  |- a4
        a = A.create
        Content.count.must_equal 1
        uid = B.schema_id.to_s
        Object.send(:remove_const, :B)
        S.schema.stubs(:classes).returns([::A])
        S.schema.reload!
        begin
          S.schema.validate!
          flunk("Validation should raise error when adding & deleting fields")
        rescue Spontaneous::SchemaModificationError => e
          @modification = e.modification
        end
        action = @modification.actions.first
        S.schema.apply(action)
        Content.count.must_equal 1
        @site.must_publish_all?.must_equal false
      end

      describe "conflict" do
        describe "-1 field" do
          before do
            A.field :a
            A.field :b
            @df1 = A.field_prototypes[:title]
            @af1 = A.field_prototypes[:a]
            @af2 = A.field_prototypes[:b]
            @uid = @df1.schema_id.to_s
            @f3 = A.field_prototypes[:introduction]
            A.stubs(:field_prototypes).returns({:a => @af1, :b => @af2, :introduction => @f3})
            A.stubs(:fields).returns([@af1, @af2, @f3])
            S.schema.reload!
            begin
              S.schema.validate!
              flunk("Validation should raise error when adding & deleting fields")
            rescue Spontaneous::SchemaModificationError => e
              @modification = e.modification
            end
          end
          it "return list of solutions for removal of one field" do
            # add :a, :b, delete :title
            # add :b, rename :title  => :a
            # add :a, rename :title  => :b
            @modification.actions.description.must_match /field 'title'/
            @modification.actions.length.must_equal 3
            action = @modification.actions[0]
            action.action.must_equal :delete
            action.source.must_equal @df1.schema_id
            action.description.must_match /delete field 'title'/i
            action = @modification.actions[1]
            action.action.must_equal :rename
            action.source.must_equal @df1.schema_id
            action.description.must_match /rename field 'title' to 'a'/i
            action = @modification.actions[2]
            action.action.must_equal :rename
            action.source.must_equal @df1.schema_id
            action.description.must_match /rename field 'title' to 'b'/i
          end

          it "enable fixing the problem by deleting field from schema" do
            action = @modification.actions[0]
            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end

            m = YAML.load_file(@map_file)
            refute m.key?(@uid)
          end

          it "enable fixing the problem by renaming field 'a'" do
            action = @modification.actions[1]
            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Renaming of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m[@uid].must_equal @af1.schema_name
          end

          it "enable fixing the problem by renaming field 'b'" do
            action = @modification.actions[2]
            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Renaming of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            m[@uid].must_equal @af2.schema_name
          end
        end

        describe "-2 fields" do
          before do
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
            S.schema.reload!
            begin
              S.schema.validate!
              flunk("Validation should raise error when adding & deleting fields")
            rescue Spontaneous::SchemaModificationError => e
              @modification = e.modification
            end
          end
          it "return list of solutions" do
            # add :a, :b; delete :title, :introduction
            # rename :title  => :a, :introduction  => :b
            # rename :introduction  => :a, :title  => :b
            # add :a; delete :introduction; rename :title  => :b
            # add :a; delete :title;        rename :introduction  => :b
            # add :b; delete :introduction; rename :title  => :a
            # add :b; delete :title;        rename :introduction  => :a
            @modification.actions.description.must_match /field 'title'/
            @modification.actions.length.must_equal 4
            action = @modification.actions[0]
            action.action.must_equal :delete
            action.source.must_equal @df1.schema_id
            action.description.must_match /delete field 'title'/i
            action = @modification.actions[1]
            action.action.must_equal :rename
            action.source.must_equal @df1.schema_id
            action.description.must_match /rename field 'title' to 'a'/i
            action = @modification.actions[2]
            action.action.must_equal :rename
            action.source.must_equal @df1.schema_id
            action.description.must_match /rename field 'title' to 'b'/i
            action = @modification.actions[3]
            action.action.must_equal :rename
            action.source.must_equal @df1.schema_id
            action.description.must_match /rename field 'title' to 'c'/i
          end

          it "enable fixing the problem by deleting both fields" do
            action = @modification.actions[0]
            begin
              S.schema.apply(action)
              flunk("Deletion of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[0]

            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            refute m.key?(@uid1)
            refute m.key?(@uid2)
          end

          it "enable fixing the problem by deleting one field and renaming other as 'a'" do
            action = @modification.actions[0]
            begin
              S.schema.apply(action)
              flunk("Deletion of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[1]

            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            refute m.key?(@uid1)
            assert m.key?(@uid2)
            m[@uid2].must_equal @af1.schema_name
          end

          it "enable fixing the problem by renaming one field as 'c' and deleting other" do
            action = @modification.actions[3]
            begin
              S.schema.apply(action)
              flunk("Renaming of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[0]

            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            assert m.key?(@uid1)
            refute m.key?(@uid2)
            m[@uid1].must_equal @af3.schema_name
          end

          it "enable fixing the problem by renaming one field as 'c' and renaming other as 'b'" do
            action = @modification.actions[3]
            begin
              S.schema.apply(action)
              flunk("Renaming of field should not have resolved schema error")
            rescue Spontaneous::SchemaModificationError => e
              modification = e.modification
            end
            action = modification.actions[2]

            begin
              S.schema.apply(action)
            rescue Spontaneous::SchemaModificationError => e
              flunk("Deletion of field should have resolved schema error")
            end
            m = YAML.load_file(@map_file)
            assert m.key?(@uid1)
            assert m.key?(@uid2)
            m[@uid1].must_equal @af3.schema_name
            m[@uid2].must_equal @af2.schema_name
          end

          describe "-2 boxes" do
            before do
              @db1 = A.boxes[:posts]
              A.box :added1
              A.box :added2
              @ab1 =  A.boxes[:added1]
              @ab2 =  A.boxes[:added2]
              boxes = S::Collections::PrototypeSet.new
              boxes[:added1] = @ab1
              boxes[:added2] = @ab2
              A.stubs(:box_prototypes).returns(boxes)
              classes = S.schema.classes.dup
              classes.delete(A::PostsBox)
              S.schema.stubs(:classes).returns(classes)
              S.schema.reload!
              begin
                S.schema.validate!
                flunk("Validation should raise error when adding & deleting fields")
              rescue Spontaneous::SchemaModificationError => e
                @modification = e.modification
              end
            end
            it "enable fixing by deleting both fields and renaming a box" do
              action = @modification.actions[0]
              begin
                S.schema.apply(action)
                flunk("Deleting of field should not have resolved schema error")
              rescue Spontaneous::SchemaModificationError => e
                modification = e.modification
              end
              action = modification.actions[0]

              begin
                S.schema.apply(action)
                flunk("Deleting of field should not have resolved schema error")
              rescue Spontaneous::SchemaModificationError => e
                modification = e.modification
              end
              action = modification.actions[1]

              begin
                S.schema.apply(action)
              rescue Spontaneous::SchemaModificationError => e
                flunk("Schema changes should have resolved error")
              end
              # p modification.actions
            end
          end
        end
      end
    end
  end
end
