# encoding: UTF-8

require 'test_helper'

class AliasTest < MiniTest::Spec

  def assert_same_content(c1, c2)
    assert_equal c1.length, c2.length
    c1.sort! { |a, b| a.id <=> b.id }
    c2.sort! { |a, b| a.id <=> b.id }
    c1.each_with_index do |a, i|
      b = c2[i]
      assert_equal a.id, b.id
      assert_equal a.class, b.class
    end
  end
  context "Aliases:" do
    setup do
      Content.delete

      @template_root = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates/aliases"))
      Spontaneous.template_root = @template_root

      class ::A < Spontaneous::Piece
        field :a_field1
        field :a_field2

        inline_style :a_style
      end

      class ::AA < ::A
        field :aa_field1
        inline_style :aa_style
      end

      class ::AAA < ::AA
        field :aaa_field1
      end

      class ::B < Page
        field :b_field1
        layout :b
      end

      class ::BB < ::B
        field :bb_field1
      end

      class ::AAlias < Piece
        alias_of :A

        field :a_alias_field1
        inline_style :a_alias_style
      end

      class ::AAAlias < Piece
        alias_of :AA
      end

      class ::AAAAlias < Piece
        alias_of :AAA
      end


      class ::BAlias < Page
        alias_of :B
      end

      class ::BBAlias < Piece
        alias_of :BB
      end

      class ::MultipleAlias < Piece
        alias_of :AA, :B
      end
      @root = Page.create
      @aliases = Page.create(:slug => "aliases").reload
      @root << @aliases
      @a = A.create.reload
      @aa = AA.create.reload
      @aaa1 = AAA.create(:aaa_field1 => "aaa1").reload
      @aaa2 = AAA.create.reload
      @b = B.new(:slug => "b")
      @root << @b
      @bb = BB.new(:slug => "bb", :bb_field1 => "BB")
      @root << @bb
      @root.save
    end

    teardown do
      [:A, :AA, :AAA, :B, :BB, :AAlias, :AAAlias, :AAAAlias, :BBAlias, :BAlias, :MultipleAlias].each do |c|
        Object.send(:remove_const, c) rescue nil
      end
      Content.delete
    end

    context "All alias" do
      context "class methods" do
        should "provide a list of available instances that includes all subclasses" do
          assert_same_content AAlias.targets, [@a, @aa, @aaa1, @aaa2]
          assert_same_content AAAlias.targets, [@aa, @aaa1, @aaa2]
          assert_same_content AAAAlias.targets, [@aaa1, @aaa2]
        end

        should "allow aliasing multiple classes" do
          assert_same_content MultipleAlias.targets, [@aa, @aaa1, @aaa2, @b, @bb]
        end

        should "be creatable with a target" do
          instance = AAlias.create(:target => @a).reload
          instance.target.should == @a
          @a.aliases.should == [instance]
        end
        should "have a back link in the target" do
          instance1 = AAlias.create(:target => @a).reload
          instance2 = AAlias.create(:target => @a).reload
          assert_same_content @a.aliases, [instance1, instance2]
        end
      end

      context "instances" do
        setup do
          @a_alias = AAlias.create(:target => @a).reload
          @aa_alias = AAAlias.create(:target => @aa).reload
          @aaa_alias = AAAAlias.create(:target => @aaa1).reload
        end

        should "have their own fields" do
          @a_alias.field?(:a_alias_field1).should be_true
        end

        # TODO
        should "reference the aliases fields before the targets"

        should "present their target's fields as their own" do
          @a_alias.field?(:a_field1).should be_true
          @a_alias.a_field1.value.should == @a.a_field1.value
        end

        should "have access to their target's fields" do
          @a_alias.target.a_field1.value.should == @a.a_field1.value
        end

        should "have their own styles" do
          @a_alias.styles.first.name.should == :a_alias_style
          @a_alias.styles.default.name.should == :a_alias_style
        end
        should "present their target's styles as their own" do
          @a_alias.styles.length.should == 2
          @a_alias.styles.map { |s| s.name }.should == [:a_alias_style, :a_style]
        end
        # should "have an independent style setting"
        should "not delete their target when deleted" do
          @a_alias.destroy
          Content[@a.id].should == @a
        end
        should "be deleted when target deleted" do
          @a.destroy
          Content[@a_alias.id].should be_nil
        end
      end
    end

    context "Piece aliases" do
      should "be allowed to target pages" do
        a = BBAlias.create(:target => @bb)
        a.bb_field1.value.should == "BB"
      end

      should "not be loadable via their compound path when linked to a page" do
        a = BBAlias.create(:target => @bb)
        @aliases << a
        @aliases.save
        Site["/aliases/bb"].should be_nil
      end
    end

    context "Page aliases" do
      should "be allowed to have piece classes as targets" do
        class ::CAlias < Page
          alias_of :AAA
          layout :c_alias
        end

        c = CAlias.new(:target => @aaa1)
        c.render.should == "aaa1\n"
      end
      should "be discoverable via their compound path" do
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases << a
        @aliases.save
        a.save
        a.reload
        a.path.should == "/aliases/b"
        Site["/aliases/balias"].should be_nil
        Site["/aliases/b"].should == a
      end

      should "render the using target's layout when accessed via the path and no local layouts defined" do
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases << a
        @aliases.save
        a.reload
        a.render.should == @b.render
      end

      should "render with locally defined style when available" do
        BAlias.layout :b_alias
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases << a
        @aliases.save
        a.reload
        a.render.should == "alternate\n"
      end

      should "have access to their target's page styles" do
        BAlias.layout :b_alias
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases << a
        @aliases.save
        a.reload
        a.layout = :b
        a.render.should == @b.render
      end
    end
  end
end

