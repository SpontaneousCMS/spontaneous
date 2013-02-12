# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class ChangeTest < MiniTest::Spec

  def setup
    @now = Time.now
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Changes" do
    setup do
      stub_time(@now)
      @revision = 1

      Content.delete

      class Page < ::Page
        field :title, :string, :default => "New Page"
        box :things
      end
      class Piece < ::Piece
        box :things
      end
    end

    teardown do
      ChangeTest.send(:remove_const, :Page) rescue nil
      ChangeTest.send(:remove_const, :Piece) rescue nil
      Content.delete_revision(@revision) rescue nil
      Content.delete_revision(@revision+1) rescue nil
      Content.delete
      DB.logger = nil
    end


    should "flag if the site has never been published" do
      root = Page.create(:title => "root")
      5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }
      result = S::Change.outstanding
      assert result.key?(:published_revision)
      result[:published_revision].should == 0
      result[:first_publish].should be_true
    end


    should "list all newly created pages" do
      root = Page.create(:title => "root")
      root[:first_published_at] = root[:last_published_at] = root.modified_at + 1000
      root.save

      5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }

      result = S::Change.outstanding
      result.must_be_instance_of(Hash)

      pages = result[:changes]
      pages.must_be_instance_of(Array)
      pages.length.should == 5

      pages.map(&:class).should == [S::Change]*5

      Set.new(pages.map(&:page_id)).should == Set.new(root.things.map { |p| p.id })
    end

    should "not list new pieces as available for publish" do
      root = Page.create(:title => "root")
      Content.publish(@revision)
      # force root to appear in the modified lists -- need this because otherwise the changes happen
      # more quickly than the resolution of the timestamps can register
      root[:first_published_at] = root[:last_published_at] = root.modified_at - 1000
      root.things << Piece.new
      root.save.reload
      result = S::Change.outstanding[:changes]
      result.length.should == 1
      result.first.page.should == root
    end

    should "not list pages that have been published" do
      root = Page.create(:title => "root")

      Content.publish(@revision)

      5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }
      root.save

      Content.publish(@revision+1, [root.id, root.things.first.id])

      result = S::Change.outstanding[:changes]
      result.length.should == 4
      Set.new(result.map(&:page_id).flatten).should == Set.new(root.things[1..-1].map(&:id))
    end

    should "group unpublished parents with their children" do
      root = Page.create(:title => "root")

      Content.publish(@revision)

      root.reload
      page1 = Page.new(:title => "Page 1")
      root.things << page1
      new_child1  = Page.new(:title => "New Child 1")
      page1.things << new_child1
      new_parent = Page.new(:title => "New Parent")
      new_child2  = Page.new(:title => "New Child 2")
      new_child3  = Page.new(:title => "New Child 3")
      root.things << new_parent
      new_parent.things << new_child2
      new_child2.things << new_child3

      pages = [root, page1, new_child1, new_parent, new_child2, new_child3]
      pages.each(&:save)


      Content.publish(@revision+1, [root.id])
      result = S::Change.outstanding[:changes]

      result.length.should == 5

      id_groups = result.map { |change|
        [change.page.id, change.dependent.map(&:id)]
      }
      Set.new(id_groups).should == Set.new([
        [page1.id, []],
        [new_child1.id, [page1.id]],
        [new_parent.id, []],
        [new_child2.id, [new_parent.id ]],
        [new_child3.id, [new_parent.id, new_child2.id]]
      ])
    end

    should "successfully publish list of dependent pages" do
      root = Page.create(:title => "root")

      Content.publish(@revision)

      root.reload
      page1 = Page.new(:title => "Page 1")
      root.things << page1
      new_child1  = Page.new(:title => "New Child 1")
      page1.things << new_child1
      new_parent = Page.new(:title => "New Parent")
      new_child2  = Page.new(:title => "New Child 2")
      new_child3  = Page.new(:title => "New Child 3")
      root.things << new_parent
      new_parent.things << new_child2
      new_child2.things << new_child3

      pages = [root, page1, new_child1, new_parent, new_child2, new_child3]
      pages.each(&:save)


      Content.publish(@revision+1, [root.id])
      result = S::Change.outstanding[:changes]

      e = nil
      begin
        pages = Spontaneous::Change.include_dependencies([new_child3])
        Content.publish(@revision+2, pages)
        Content.delete_revision(@revision + 2) rescue nil
      rescue => e
        Content.delete_revision(@revision + 2) rescue nil
        raise
      end
    end

    should "provide page & dependency information in serializable format" do
      root = Page.create(:title => "root")

      Content.publish(@revision)

      root.reload
      page1 = Page.new(:title => "Page 1")
      root.things << page1
      new_child1  = Page.new(:title => "New Child 1")
      page1.things << new_child1
      root.save

      Content.publish(@revision+1, [root.id])
      result = S::Change.outstanding[:changes]
      change = result.detect { |change| change.page.id == new_child1.id }
      change.export.should == {
        :id => new_child1.id,
        :title => new_child1.title.value,
        :url => new_child1.path,
        :published_at => nil,
        :modified_at => new_child1.modified_at.httpdate,
        # :editor_login => "someone",
        :depth => new_child1.depth,
        :side_effects => {},
        :update_locks => [],
        :dependent => [{
          :id => page1.id,
          :depth => page1.depth,
          :title => page1.title.value,
          :url => page1.path,
          :side_effects => {},
          :update_locks => [],
          :published_at => nil,
          :modified_at => page1.modified_at.httpdate,
        }]
      }
    end

    should "order modified changes in reverse modification date order" do
      root = Page.create(:title => "root")

      Content.publish(@revision)

      root.reload
      page1 = Page.new(:title => "Page 1")
      root.things << page1
      new_child1  = Page.new(:title => "New Child 1")
      page1.things << new_child1
      root.save
      last = Time.now + 100
      ::Content.filter(:id => new_child1.id).update(:modified_at => last)
      result = S::Change.outstanding[:changes]
      assert result.first.modified_at > result.last.modified_at, "Change list in incorrect order"
    end

    should "provide information on side effects of publishing page with path changes" do
      root = Page.create(:title => "root")


      root.reload
      page1 = Page.new(:title => "Page 1")
      root.things << page1
      new_child1  = Page.new(:title => "New Child 1")
      page1.things << new_child1
      root.save

      Content.publish(@revision)

      later = @now + 10
      stub_time(later)
      old_slug = page1.slug
      page1.slug = "changed"
      page1.save

      result = S::Change.outstanding[:changes]

      change = result.detect { |change| change.page.id == page1.id }
      change.export[:side_effects].should == {
        :slug => [{ :count => 1, :created_at => later.httpdate, :old_value => old_slug, :new_value => "changed"}]
      }
    end

    should "provide information on side effects of publishing page with visibility changes" do
      root = Page.create(:title => "root")


      root.reload
      page1 = Page.new(:title => "Page 1")
      root.things << page1
      new_child1  = Page.new(:title => "New Child 1")
      page1.things << new_child1
      root.save

      Content.publish(@revision)

      later = @now + 10
      stub_time(later)
      page1.hide!

      page1.reload
      result = S::Change.outstanding[:changes]
      change = result.detect { |change| change.page.id == page1.id }
      change.export[:side_effects].should == {
        :visibility => [{ :count => 1, :created_at => later.httpdate, :old_value => false, :new_value => true}]
      }
    end

    should "provide information about any update locks that exist on a page" do
      Piece.field :async
      page = Page.create(:title => "page")


      piece = Piece.new

      page.things << piece
      page.save
      piece.save

      lock = Spontaneous::PageLock.create(:page_id => page.id, :content_id => piece.id, :field_id => piece.async.id, :description => "Update Lock")
      page.locked_for_update?.should be_true
      result = S::Change.outstanding[:changes]
      change = result.detect { |change| change.page.id == page.id }
      change.export[:update_locks].should == [{
        id: lock.id,
        content_id: piece.id,
        field_id: piece.async.id,
        field_name: :async,
        location: "Field ‘async’ of entry 1 in box ‘things’",
        description: "Update Lock",
        created_at: @now.httpdate
      }]
    end
  end
end
