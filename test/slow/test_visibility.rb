# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class VisibilityTest < MiniTest::Spec


  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Content" do
    setup do
      Content.delete
      class ::R < Page; end
      R.box :pages
      class ::P < Page; end
      P.box :things
      class ::E < Piece; end
      E.box :pages

      @root = R.new(:uid => 'root')
      2.times do |i|
        c = P.new(:uid => i, :slug => "#{i}")
        @root.pages << c
        4.times do |j|
          d = E.new(:uid => "#{i}.#{j}")
          c.things << d
          2.times do |k|
            e = P.new(:uid => "#{i}.#{j}.#{k}", :slug => "#{i}-#{j}-#{k}")
            d.pages << e
            2.times do |l|
              e.things << E.new(:uid => "#{i}.#{j}.#{k}.#{l}")
            end
            e.save
          end
        end
      end
      @root.save
      @root.reload
      @child = Page.uid("0")
    end

    teardown do
      [:R, :P, :E].each do |k|
        Object.send(:remove_const, k)
      end
      Spontaneous.database.logger = nil
      Content.delete
    end

    should "be visible by default" do
      @child.visible?.should be_true
    end

    should "be hidable using #hide!" do
      @child.hide!
      @child.visible?.should be_false
      @child.hidden?.should be_true
    end

    should "be hidable using #visible=" do
      @child.visible = false
      @child.visible?.should be_false
      @child.hidden?.should be_true
    end

    should "hide child pages" do
      @child.page?.should be_true
      @child.hide!
      @child.children.each do |child1|
        child1.visible?.should be_false
        child1.hidden_origin.should == @child.id
        child1.children.each do |child2|
          child2.visible?.should be_false
          child2.hidden_origin.should == @child.id
        end
      end
    end

    should "hide page content" do
      @child.hide!
      @child.reload
      Piece.all.select { |f| f.visible? }.length.should == 20
      Piece.all.select do |f|
        f.page.ancestors.include?(@child) || f.page == @child
      end.each do |f|
        f.visible?.should be_false
        f.hidden_origin.should == @child.id
      end
      Piece.all.select do | f |
        !f.page.ancestors.include?(@child) && f.page != @child
      end.each do |f|
        f.visible?.should be_true
        f.hidden_origin.should be_nil
      end
    end

    should "re-show all page content" do
      @child.hide!
      @child.show!
      @child.reload
      Content.all.each do |c|
        c.visible?.should be_true
        c.hidden_origin.should be_nil
      end
    end

    should "hide all descendents of page content" do
      piece = Content.first(:uid => "0.0")
      f = E.new(:uid => "0.0.X")
      piece.pages << f
      piece.save
      piece.reload
      piece.hide!

      Content.all.each do |c|
        if c.uid =~ /^0\.0/
          c.hidden?.should be_true
          if c.uid == "0.0"
            c.visible?.should be_false
            c.hidden_origin.should be_nil
          else
            c.visible?.should be_false
            c.hidden_origin.should == piece.id
          end
        else
          c.hidden?.should be_false
          c.hidden_origin.should be_nil
        end
      end

    end

    should "re-show all descendents of page content" do
      piece = Content.first(:uid => "0.0")
      piece.hide!
      piece.show!
      Content.all.each do |c|
        c.visible?.should be_true
        c.hidden_origin.should be_nil
      end
    end

    should "know if something is hidden because its ancestor is hidden" do
      piece = Content.first(:uid => "0.0")
      piece.hide!
      piece.showable?.should be_true
      child = Content.first(:uid => "0.0.0.0")
      child.visible?.should be_false
      child.showable?.should be_false
    end

    # showing something that is hidden because its ancestor is hidden shouldn't be possible
    should "stop hidden child content from being hidden" do
      piece = Content.first(:uid => "0.0")
      piece.hide!
      child = Content.first(:uid => "0.0.0.0")
      child.visible?.should be_false
      lambda { child.show! }.must_raise(Spontaneous::NotShowable)
    end

    should "not reveal child content that was hidden before its parent" do
      piece1 = Content.first(:uid => "0.0.0.0")
      piece2 = Content.first(:uid => "0.0.0.1")
      parent = Content.first(:uid => "0.0.0")
      piece1.owner.should == parent
      piece2.owner.should == parent
      piece1.container.should == parent.things
      piece2.container.should == parent.things
      piece1.hide!
      parent.hide!
      parent.reload.visible?.should be_false
      piece1.reload.visible?.should be_false
      piece2.reload.visible?.should be_false
      piece1.hidden_origin.should be_blank
      piece2.hidden_origin.should == parent.id
      parent.show!
      parent.reload.visible?.should be_true
      piece2.reload.visible?.should be_true
      piece1.reload.visible?.should be_false
    end



    context "root" do
      should "should not be hidable" do
        @root.is_root?.should be_true
        lambda { @root.visible = false }.must_raise(RuntimeError)
        lambda { @root.hide! }.must_raise(RuntimeError)
        @root.visible?.should be_true
      end
    end

    context "top-level searches" do
      should "return a list of visible pages" do
        @root.pages.first.hide!
        P.visible.count.should == 9
      end
    end
    context "visibility scoping" do
      setup do
        # S.database.logger = ::Logger.new($stdout)
      end

      teardown do
        # S.database.logger = nil
      end

      should "prevent inclusion of hidden content" do
        @uid = '0'
        @page = Page.uid(@uid)
        @page.hide!
        @page.reload
        # Spontaneous.database.logger = ::Logger.new($stdout)
        Page.path("/0").should == @page
        Content.with_visible do
          Content.visible_only?.should be_true
          Page.uid(@uid).should be_blank
          Page.path("/0").should be_blank
          Page.uid('0.0.0').should be_blank
        end
      end

      should "only show visible pieces" do
        page = Content.first(:uid => "1")
        page.pieces.length.should == 4
        page.things.pieces.length.should == 4
        page.things.count.should == 4
        page.pieces.first.hide!
        page.reload
        Content.with_visible do
          page.pieces.length.should == 3
          page.pieces.first.id.should_not == page.id
          page.pieces.first.first?.should be_true
        end
      end

      should "stop modification of pieces" do
        page = Content.first(:uid => "1")
        Content.with_visible do
          # would like to make sure we're raising a predictable error
          # but 1.9 changes the typeerror to a runtime error
          lambda { page.things << Piece.new }.must_raise(TypeError, RuntimeError)
        end
      end

      should "ensure that no hidden content can be returned" do
        @root.reload
        @root.children.first.children.length.should == 8
        @root.children.first.pieces.first.hide!
        @root.reload
        Content.with_visible do
          @root.children.first.children.length.should == 6
        end
      end

      should "hide pages without error" do
        @root.pages.first.hide!
        @root.reload
        Content.with_visible do
          pieces = @root.pages.pieces.map { |p| p }
        end
      end
    end

    context "aliases" do
      setup do
        class ::MyAlias < Piece; end
        MyAlias.alias_of ::E
      end

      teardown do
        Object.send(:remove_const, :MyAlias)
      end

      should "be initalized as invisible if their target is invisible" do
        target = E.find(:uid => "1.1")
        target.hide!
        al = MyAlias.create(:target => target)
        al.visible?.should be_false
      end

      should "be made visible along with their target if added when target is hidden" do
        target = E.find(:uid => "1.1")
        target.hide!
        al = MyAlias.create(:target => target)
        al.reload.visible?.should be_false
        target.show!
        al.reload.visible?.should be_true
      end
    end
  end
end
