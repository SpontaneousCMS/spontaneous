# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Alias" do

  start do
    site = setup_site
    template_root = File.expand_path(File.join(File.dirname(__FILE__), "../fixtures/templates/aliases"))
    let(:template_root) { template_root }
    site.paths.add(:templates, template_root)
    renderer = S::Output::Template::Renderer.new(site, false)
    let(:renderer) { renderer }
    let(:site) { site }

    Content.delete

    Page.field :title
    Page.box :box1
    Page.box :box2

    class ::A < ::Piece
      field :a_field1
      field :a_field2
      field :image, :image

      style :a_style
      def alias_title
        a_field1.value
      end
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
      alias_of proc { Content.root.children }
    end

    Content.scope(nil, false) do
      root = ::Page.create
      aliases = ::Page.create(:slug => "aliases").reload
      root.box1 << aliases
      box = aliases.box1
      a = box.push A.new(:a_field1 => "@a.a_field1")
      aa = box.push AA.new
      aaa1 = box.push AAA.new(:aaa_field1 => "aaa1")
      aaa2 = box.push AAA.new
      b = root.box1.push B.new(:slug => "b")
      bb = root.box1.push BB.new(:slug => "bb", :bb_field1 => "BB")
      root.save.reload

      let(:root) { root }
      let(:aliases) { aliases }
      let(:a) { a }
      let(:aa) { aa }
      let(:aaa1) { aaa1 }
      let(:aaa2) { aaa2 }
      let(:b) { b }
      let(:bb) { bb }
    end
  end

  finish do
    [:A, :AA, :AAA, :B, :BB, :AAlias, :AAAlias, :AAAAlias, :BBAlias, :BAlias, :MultipleAlias, :ProcAlias].each do |c|
      Object.send(:remove_const, c) rescue nil
    end
    Content.delete
    teardown_site
  end

  def assert_same_content(c1, c2)
    assert_equal c2.length, c1.length
    c1 = c1.dup.sort { |a, b| a.id <=> b.id }
    c2 = c2.dup.sort { |a, b| a.id <=> b.id }
    c1.each_with_index do |a, i|
      b = c2[i]
      assert_equal b.id, a.id
      assert_equal b.class, a.class
    end
  end

  before do
    @site = site
  end

  after do
  end

  describe "All alias" do
    describe "class methods" do
      it "provide a list of available instances that includes all subclasses" do
        assert_same_content AAlias.targets, [a, aa, aaa1, aaa2]
        assert_same_content AAAlias.targets, [aa, aaa1, aaa2]
        assert_same_content AAAAlias.targets, [aaa1, aaa2]
      end

      it "use the first available string field as the alias title" do
        Piece.field :something
        target = Piece.new(:something => "something")
        target.alias_title.must_equal "something"
      end

      it "allow aliasing multiple classes" do
        assert_same_content MultipleAlias.targets, [aa, aaa1, aaa2, b, bb]
      end

      it "be creatable with a target" do
        instance = AAlias.create(:target => a).reload
        instance.target.must_equal a
        a.reload.aliases.must_equal [instance]
      end

      it "have a back link in the target" do
        instance1 = AAlias.create(:target => a).reload
        instance2 = AAlias.create(:target => a).reload
        assert_same_content a.reload.aliases, [instance1, instance2]
      end

      it "accept a proc that returns an array as a target list generator" do
        assert_same_content ProcAlias.targets, root.children
      end

      describe "with container options" do
        before do
          Content.scope(nil, false) do
            @page = root.box1 << ::Page.new(uid: "thepage")
            4.times { |n|
              @page.box1 << A.new
              @page.box1 << AA.new
              @page.box2 << A.new
              @page.box2 << AA.new
            }
            @page = @page.save.reload
          end
        end

        after do
          Object.send(:remove_const, 'X') rescue nil
          Object.send(:remove_const, 'XX') rescue nil
          Object.send(:remove_const, 'XXX') rescue nil
        end

        it "allow for selecting only content from within one box" do
          container_proc = Proc.new { site['$thepage'].box1 }
          ::X = Class.new(::Piece) do
            alias_of :A, :container => container_proc
          end
          ::XX = Class.new(::Piece) do
            alias_of :AA, :container => container_proc
          end
          targets = lambda { |a, target|
            [(a.targets), @page.box1.select { |p| target === p }].map { |a| Set.new(a) }
          }
          expected, actual = targets.call(X, A)
          actual.must_equal expected
          expected, actual = targets.call(XX, AA)
          actual.must_equal expected
        end

        it "allow for selecting only content from a range of boxes" do
          container_proc = Proc.new { [site['$thepage'].box1, site['$thepage'].box2] }
          ::X = Class.new(::Piece) do
            alias_of :A, :container => container_proc
          end
          ::XX = Class.new(::Piece) do
            alias_of :AA, :container => container_proc
          end
          assert_same_content X.targets, @page.box1.select { |p| A === p } + @page.box2.select { |p| A === p }
          assert_same_content XX.targets, @page.box1.select { |p| AA === p } + @page.box2.select { |p| AA === p }
        end

        it "allow for selecting only content from within one page" do
          container_proc = Proc.new { site['$thepage'] }
          ::X = Class.new(::Piece) do
            alias_of :A, :container => container_proc
          end
          ::XX = Class.new(::Piece) do
            alias_of :AA, :container => container_proc
          end
          assert_same_content X.targets, @page.content.select { |p| A === p }
          assert_same_content XX.targets, @page.content.select { |p| AA === p }
        end

        it "allow for selecting only content from a range of pages & boxes" do
          page2 = ::Page.new(:uid => "thepage2")
          4.times { |n|
            page2.box1 << A.new
            page2.box1 << AA.new
            page2.box2 << A.new
            page2.box2 << AA.new
          }
          page2.reload
          container_proc = Proc.new { [site['$thepage'].box1, site['$thepage2']] }
          ::X = Class.new(::Piece) do
            alias_of :A, :AA, :container => container_proc
          end
          container_proc = Proc.new { [site['$thepage'], site['$thepage2'].box2] }
          ::XX = Class.new(::Piece) do
            alias_of :AA, :container => container_proc
          end
          assert_same_content X.targets(@page, @page.box1), @page.box1.contents + page2.content
          assert_same_content XX.targets, @page.content.select { |p| AA === p } + page2.box2.select { |p| AA === p }
        end

        it "allow for selecting content only from the content of the owner of the box" do
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

        it "allow for filtering instances according to some arbitrary proc" do
          pieces = [@page.box1.entries.first, @page.box2.entries.first]
          _filter = lambda { |c|
            pieces.map(&:id).include?(c.id)
          }
          ::X  = Class.new(::Piece) do
            alias_of :A, :filter => _filter
          end
          assert_same_content pieces, X.targets
        end

        it "allow for filtering instances according to current page content" do
          @page.box1 << AAA.create
          @page.box2 << AAA.create
          @page.save.reload
          allowable = AAA.all - @page.box1.contents.to_a
          ::X  = Class.new(::Piece) do
            alias_of :AAA, :filter => proc { |choice, page, box| !box.include?(choice) }
          end
          assert_same_content allowable, X.targets(@page, @page.box1)
        end

        it "allow for ensuring the uniqueness of the entries" do
          aaa = AAA.all
          ::X  = Class.new(::Piece) do
            alias_of :AAA, :unique => true
          end
          @page.box1 << aaa.first
          @page.save.reload
          assert_same_content [aaa.last], X.targets(@page, @page.box1)
        end

        it "allows for enforcing unique page aliases" do
          bb = BB.all
          b1 = @page.box1 << BB.new

          ::X  = Class.new(::Page) do
            alias_of :BB, unique: true
          end

          bb.each { |b| @page.box2 << X.new(target: b) }

          targets = X.targets(@page, @page.box2)
          assert_same_content targets, [b1]
        end

        it "allow for returning an arbitrary list of results generated by a proc" do
          results = [mock, mock, mock]
          ::X  = Class.new(::Piece) do
            alias_of proc { results }
          end
          ::X.targets.must_equal  results
        end

      end
    end

    describe "instances" do
      before do
        @a_alias = AAlias.create(:target => a).reload
        @aa_alias = AAAlias.create(:target => aa).reload
        @aaa_alias = AAAAlias.create(:target => aaa1).reload
      end

      it "have their own fields" do
        assert @a_alias.field?(:a_alias_field1)
      end

      it "provide access to their target" do
        @a_alias.target.must_equal a
      end


      it "present their target's fields as their own" do
        assert @a_alias.field?(:a_field1)
        @a_alias.a_field1.value.must_equal a.a_field1.value
      end

      it "have access to their target's fields" do
        @a_alias.target.a_field1.value.must_equal a.a_field1.value
      end

      it "provide transparent access target's fields" do
        @a_alias.a_field1.value.must_equal a.a_field1.value
      end

      it "provide transparent access target's fields with hash notation" do
        @a_alias.fields[:a_field1].value.must_equal a.a_field1.value
      end

      it "have their own styles" do
        assert_correct_template(@a_alias,  template_root / 'a_alias/a_alias_style', renderer)
      end

      it "present their target's styles as their own" do
        @a_alias.style = :a_style

        assert_correct_template(@a_alias,  template_root / 'a/a_style', renderer)
      end

      it "should use templates belonging to the alias class if they exist" do
        assert_correct_template(@aa_alias,  template_root / 'aa_alias', renderer)
      end

      it "should fallback to the targets default style if no alias template is present" do
        assert_correct_template(@aaa_alias,  aaa1.template, renderer)
      end

      # should "have an independent style setting"
      it "not delete their target when deleted" do
        @a_alias.destroy
        Content[a.id].must_equal a
      end

      it "be deleted when target deleted" do
        a.destroy
        Content[@a_alias.id].must_be_nil
      end

      it "include target values in serialisation" do
        @a_alias.export[:target].must_equal a.shallow_export(nil)
      end

      it "include alias title & icon in serialisation" do
        @a_alias.export[:alias_title].must_equal a.alias_title
        @a_alias.export[:alias_icon].must_equal a.alias_icon_field.export
      end
    end
  end

  describe "Aliases to custom models" do
    before do
      @target_id = target_id = 9999
      @target = target = mock()
      @target.stubs(:id).returns(@target_id)
      @target.stubs(:title).returns("custom object")
      @target.stubs(:hidden?).returns(false)

      @custom_alias_class = Class.new(::Page) do
        alias_of proc { [target] }, :lookup => lambda { |id|
          return target if id == target_id
          nil
        }, :slug => lambda { |target| target.title.to_url }
      end
    end
    it "be creatable using a custom initializer" do
      a = @custom_alias_class.for_target(@target_id)

      a.target_id.must_equal @target_id
      a.target.must_equal @target
    end

    it "be able to provide a slug for pages" do
      a = @custom_alias_class.for_target(@target_id)
      a.target.must_equal @target
      a.slug.must_equal "custom-object"
    end

    it "ignore styles if object doesn't provide them" do
      a = @custom_alias_class.for_target(@target_id)
      a.style.template.call.must_equal Page.new.style.template.call
    end
  end


  describe "Piece aliases" do
    it "be allowed to target pages" do
      a = BBAlias.create(:target => bb)
      a.bb_field1.value.must_equal "BB"
    end

    it "not be loadable via their compound path when linked to a page" do
      a = BBAlias.create(:target => bb)
      aliases.box1 << a
      aliases.save
      site["/aliases/bb"].must_be_nil
    end

    it "have their target's path attribute if they alias to a page type" do
      a = BBAlias.create(:target => bb)
      a.path.must_equal bb.path
    end
  end

  describe "Page aliases" do
    before do
      BAlias.instance_variable_set(:@layout_prototypes, nil)
      aliases.reload
      b.reload
    end
    it "be allowed to have piece classes as targets" do
      class ::CAlias < Page
        alias_of :AAA
        layout :c_alias
      end

      c = CAlias.new(:target => aaa1)
      c.render.must_equal "aaa1\n"
    end

    it "respond as a page" do
      a = BAlias.create(:target => b, :slug => "balias")
      assert a.page?
    end

    it "be discoverable via their compound path" do
      a = BAlias.create(:target => b, :slug => "balias")
      aliases.box1 << a
      aliases.save
      a.save
      a.reload
      a.path.must_equal "/aliases/b"
      site["/aliases/balias"].must_be_nil
      site["/aliases/b"].must_equal a
    end

    it "update their path if their target's slug changes" do
      al = BAlias.create(:target => b, :slug => "balias")
      bl = BAlias.create(:target => b, :slug => "balias")
      aliases.box1 << al
      al.box1 << bl
      aliases.save

      al.save
      al.reload
      al.path.must_equal "/aliases/b"
      bl.path.must_equal "/aliases/b/b"
      b.slug = "newb"
      b.save
      al.reload
      bl.reload
      al.path.must_equal "/aliases/newb"
      bl.path.must_equal "/aliases/newb/newb"
    end

    it "include target values in serialisation" do
      al = BAlias.create(:target => b)
      al.export[:target].must_equal b.shallow_export(nil)
    end

    it "include target values in entry serialisation" do
      al = BAlias.create(:target => b)
      aliases.box1 << al
      aliases.save
      al.entry.export[:target].must_equal b.shallow_export(nil)
    end

    it "update their path if their parent's path changes" do
      al = BAlias.create(:target => b, :slug => "balias")
      bl = BAlias.create(:target => b, :slug => "balias")
      aliases.box1 << al
      al.box1 << bl
      aliases.save
      al.save
      al.reload
      al.path.must_equal "/aliases/b"
      bl.path.must_equal "/aliases/b/b"
      aliases.slug = "newaliases"
      aliases.save
      al.reload
      bl.reload
      al.path.must_equal "/newaliases/b"
      bl.path.must_equal "/newaliases/b/b"
    end

    it "show in the parent's list of children" do
      al = BAlias.create(:target => b, :slug => "balias")
      aliases.box1 << al
      aliases.save
      al.save
      al.reload
      aliases.reload
      aliases.children.must_equal [al]
      al.parent.must_equal aliases
    end

    it "render the using target's layout when accessed via the path and no local layouts defined" do
      al = BAlias.create(:target => b, :slug => "balias")
      aliases.box1 << al
      aliases.save
      al.reload
      al.render.must_equal b.render
    end

    it "render with locally defined style when available" do
      BAlias.layout :b_alias
      al = BAlias.new(:target => b, :slug => "balias")
      aliases.box1 << al
      aliases.save
      al.reload
      al.render.must_equal "alternate\n"
    end

    it "have access to their target's page styles" do
      BAlias.layout :b_alias
      a = BAlias.create(:target => b, :slug => "balias")
      aliases.box1 << a
      aliases.save
      a.reload
      a.layout = :b
      a.render.must_equal b.render
    end
  end

  describe "visibility" do
    after do
      b.show!
    end

    it "be linked to the target's visibility" do
      a = BAlias.create(:target => b, :slug => "balias")
      b.hide!
      b.reload
      a.reload
      refute a.visible?
      refute a[:visible]
    end

    it 'is adopted from the target when added' do
      b.hide!
      a = BAlias.new(:target => b, :slug => "balias")
      root.box1 << a
      a.save
      attrs = a.attributes
      assert attrs[:hidden]
      attrs[:hidden_origin].must_equal b.id
    end
  end
end
