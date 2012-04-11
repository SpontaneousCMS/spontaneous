# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class AliasTest < MiniTest::Spec

  def assert_same_content(c1, c2)
    assert_equal c1.length, c2.length
    c1 = c1.dup.sort { |a, b| a.id <=> b.id }
    c2 = c2.dup.sort { |a, b| a.id <=> b.id }
    c1.each_with_index do |a, i|
      b = c2[i]
      assert_equal a.id, b.id
      assert_equal a.class, b.class
    end
  end

  context "Aliases:" do
    setup do
      @site = setup_site
      @template_root = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates/aliases"))
      @site.paths.add(:templates, @template_root)

      Content.delete

      class ::Page < Spontaneous::Page
        field :title
        box :box1
        box :box2
      end

      class ::Piece < Spontaneous::Piece; end

      class ::A < ::Piece
        field :a_field1
        field :a_field2
        field :image, :image

        style :a_style
        def alias_title
          a_field1.value
        end

        # def alias_icon_field
        #   "/aliasicon.png"
        # end
      end

      class ::AA < ::A
        field :aa_field1
        style :aa_style
      end

      class ::AAA < ::AA
        field :aaa_field1
      end

      class ::B < ::Page
        field :b_field1
        layout :b
      end

      class ::BB < ::B
        field :bb_field1

        box :box1
      end

      class ::AAlias < ::Piece
        alias_of :A

        field :a_alias_field1
        style :a_alias_style
      end

      class ::AAAlias < ::Piece
        alias_of :AA
      end

      class ::AAAAlias < ::Piece
        alias_of :AAA
      end


      class ::BAlias < ::Page
        alias_of :B
        box :box1
      end

      class ::BBAlias < ::Piece
        alias_of :BB
      end

      class ::MultipleAlias < ::Piece
        alias_of :AA, :B
      end

      class ::ProcAlias < ::Piece
        alias_of proc { Spontaneous::Site.root.children }
      end

      @root = ::Page.create
      @aliases = ::Page.create(:slug => "aliases").reload
      @root.box1 << @aliases
      @a = A.create(:a_field1 => "@a.a_field1").reload
      @aa = AA.create.reload
      @aaa1 = AAA.create(:aaa_field1 => "aaa1").reload
      @aaa2 = AAA.create.reload
      @b = B.new(:slug => "b")
      @root.box1 << @b
      @bb = BB.new(:slug => "bb", :bb_field1 => "BB")
      @root.box1 << @bb
      @root.save.reload
    end

    teardown do
      [:Page, :Piece, :A, :AA, :AAA, :B, :BB, :AAlias, :AAAlias, :AAAAlias, :BBAlias, :BAlias, :MultipleAlias, :ProcAlias].each do |c|
        Object.send(:remove_const, c) rescue nil
      end
      Content.delete
      FileUtils.rm_r(@site.root)
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

        should "accept a proc that returns an array as a target list generator" do
          assert_same_content ProcAlias.targets, @root.children
        end

        context "with container options" do
          setup do
            @page = ::Page.new(:uid => "thepage")
            4.times { |n|
              @page.box1 << A.new
              @page.box1 << AA.new
              @page.box2 << A.new
              @page.box2 << AA.new
            }
            @page.save.reload
          end

          teardown do
            Object.send(:remove_const, 'X') rescue nil
            Object.send(:remove_const, 'XX') rescue nil
            Object.send(:remove_const, 'XXX') rescue nil
          end

          should "allow for selecting only content from within one box" do
            class ::X < ::Piece
              alias_of :A, :container => Proc.new { S::Site['#thepage'].box1 }
            end
            class ::XX < ::Piece
              alias_of :AA, :container => Proc.new { S::Site['#thepage'].box1 }
            end
            Set.new(X.targets).should == Set.new(@page.box1.select { |p| A === p })
            Set.new(XX.targets).should == Set.new(@page.box1.select { |p| AA === p })
          end

          should "allow for selecting only content from a range of boxes" do
            class ::X < ::Piece
              alias_of :A, :container => Proc.new { [S::Site['#thepage'].box1, S::Site['#thepage'].box2] }
            end
            class ::XX < ::Piece
              alias_of :AA, :container => Proc.new { [S::Site['#thepage'].box1, S::Site['#thepage'].box2] }
            end
            assert_same_content X.targets, @page.box1.select { |p| A === p } + @page.box2.select { |p| A === p }
            assert_same_content XX.targets, @page.box1.select { |p| AA === p } + @page.box2.select { |p| AA === p }
          end

          should "allow for selecting only content from within one page" do
            class ::X < ::Piece
              alias_of :A, :container => Proc.new { S::Site['#thepage'] }
            end
            class ::XX < ::Piece
              alias_of :AA, :container => Proc.new { S::Site['#thepage'] }
            end
            assert_same_content X.targets, @page.content.select { |p| A === p }
            assert_same_content XX.targets, @page.content.select { |p| AA === p }
          end

          should "allow for selecting only content from a range of pages & boxes" do
            page2 = ::Page.new(:uid => "thepage2")
            4.times { |n|
              page2.box1 << A.new
              page2.box1 << AA.new
              page2.box2 << A.new
              page2.box2 << AA.new
            }
            page2.save.reload
            class ::X < ::Piece
              alias_of :A, :AA, :container => Proc.new { [S::Site['#thepage'].box1, S::Site['#thepage2']] }
            end
            class ::XX < ::Piece
              alias_of :AA, :container => Proc.new { [S::Site['#thepage'], S::Site['#thepage2'].box2] }
            end
            assert_same_content X.targets(@page, @page.box1), @page.box1.contents + page2.content
            assert_same_content XX.targets, @page.content.select { |p| AA === p } + page2.box2.select { |p| AA === p }
          end

          should "allow for selecting content only from the content of the owner of the box" do
            class ::X < ::Piece
              alias_of proc { |owner| owner.box1.contents }
            end
            class ::XX < ::Piece
              alias_of proc { |owner, box| box.contents }
            end
            class ::XXX < ::Piece
              alias_of :A, :container => proc { |owner, box| box }
            end
            assert_same_content X.targets(@page), @page.box1.contents
            assert_same_content XX.targets(@page, @page.box1), @page.box1.contents
            assert_same_content XX.targets(@page, @page.box2), @page.box2.contents
            assert_same_content XXX.targets(@page, @page.box1), @page.box1.contents.select { |p| A === p }
          end

          should "allow for filtering instances according to some arbitrary proc" do
            pieces = [@page.box1.entries.first, @page.box2.entries.first]
            _filter = lambda { |c|
              pieces.map(&:id).include?(c.id)
            }
            ::X  = Class.new(::Piece) do
              alias_of :A, :filter => _filter
            end
            assert_same_content pieces, X.targets
          end

          should "allow for filtering instances according to current page content" do
            @page.box1 << AAA.create
            @page.box2 << AAA.create
            @page.save.reload
            allowable = AAA.all - @page.box1.contents
            ::X  = Class.new(::Piece) do
              alias_of :AAA, :filter => proc { |choice, page, box| !box.include?(choice) }
            end
            assert_same_content allowable, X.targets(@page, @page.box1)
          end

          should "allow for ensuring the uniqueness of the entries" do
            aaa = AAA.all
            ::X  = Class.new(::Piece) do
              alias_of :AAA, :unique => true
            end
            @page.box1 << aaa.first
            @page.save.reload
            assert_same_content [aaa.last], X.targets(@page, @page.box1)
          end
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

        should "provide access to their target" do
          @a_alias.target.should == @a
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
          assert_correct_template(@a_alias,  @template_root / 'a_alias/a_alias_style')
        end

        should "present their target's styles as their own" do
          @a_alias.style = :a_style

          assert_correct_template(@a_alias,  @template_root / 'a/a_style')
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

        should "include target values in serialisation" do
          @a_alias.export[:target].should == @a.shallow_export(nil)
        end

        should "include alias title & icon in serialisation" do
          @a_alias.export[:alias_title].should == @a.alias_title
          @a_alias.export[:alias_icon].should == @a.alias_icon_field.export
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
        @aliases.box1 << a
        @aliases.save
        Site["/aliases/bb"].should be_nil
      end

      should "have their target's path attribute if they alias to a page type" do
        a = BBAlias.create(:target => @bb)
        a.path.should == @bb.path
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

      should "respond as a page" do
        a = BAlias.create(:target => @b, :slug => "balias")
        a.page?.should be_true
      end

      should "be discoverable via their compound path" do
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        @aliases.save
        a.save
        a.reload
        a.path.should == "/aliases/b"
        Site["/aliases/balias"].should be_nil
        Site["/aliases/b"].should == a
      end

      should "update their path if their target's slug changes" do
        a = BAlias.create(:target => @b, :slug => "balias")
        b = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        a.box1 << b
        @aliases.save

        a.save
        a.reload
        a.path.should == "/aliases/b"
        b.path.should == "/aliases/b/b"
        @b.slug = "newb"
        @b.save
        a.reload
        b.reload
        a.path.should == "/aliases/newb"
        b.path.should == "/aliases/newb/newb"
      end

      should "update their path if their parent's path changes" do
        a = BAlias.create(:target => @b, :slug => "balias")
        b = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        a.box1 << b
        @aliases.save
        a.save
        a.reload
        a.path.should == "/aliases/b"
        b.path.should == "/aliases/b/b"
        @aliases.slug = "newaliases"
        @aliases.save
        a.reload
        b.reload
        a.path.should == "/newaliases/b"
        b.path.should == "/newaliases/b/b"
      end

      should "show in the parent's list of children" do
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        @aliases.save
        a.save
        a.reload
        @aliases.reload
        @aliases.children.should == [a]
        a.parent.should == @aliases
      end

      should "render the using target's layout when accessed via the path and no local layouts defined" do
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        @aliases.save
        a.reload
        a.render.should == @b.render
      end

      should "render with locally defined style when available" do
        BAlias.layout :b_alias
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        @aliases.save
        a.reload
        a.render.should == "alternate\n"
      end

      should "have access to their target's page styles" do
        BAlias.layout :b_alias
        a = BAlias.create(:target => @b, :slug => "balias")
        @aliases.box1 << a
        @aliases.save
        a.reload
        a.layout = :b
        a.render.should == @b.render
      end
    end

    context "visibility" do
      should "be linked to the target's visibility" do
        a = BAlias.create(:target => @b, :slug => "balias")
        @b.hide!
        @b.reload
        a.reload
        a.visible?.should be_false
      end
    end
  end
end

