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
      @revision = 1
      stub_time(@now)

      # DB.logger = Logger.new($stdout)
      Content.delete

      class Page < Spontaneous::Page
        field :title, :string, :default => "New Page"
        box :things
      end
      class Piece < Spontaneous::Piece
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



    should "list all newly created pages" do
      root = Page.create(:title => "root")
      root[:first_published_at] = root[:last_published_at] = root.modified_at + 1000
      root.save

      5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }

      result = Change.outstanding
      result.must_be_instance_of(Array)
      result.length.should == 5

      result.map(&:class).should == [Change]*5

      Set.new(result.map(&:page_id)).should == Set.new(root.things.map { |p| p.id })
    end

    should "not list new pieces as available for publish" do
      root = Page.create(:title => "root")
      Content.publish(@revision)
      # force root to appear in the modified lists -- need this because otherwise the changes happen
      # more quickly than the resolution of the timestamps can register
      root[:first_published_at] = root[:last_published_at] = root.modified_at - 1000
      root.things << Piece.new
      root.save.reload
      result = Change.outstanding
      result.length.should == 1
      result.first.page.should == root
    end

    should "not list pages that have been published" do
      root = Page.create(:title => "root")

      Content.publish(@revision)

      5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }
      root.save

      Content.publish(@revision+1, [root.id, root.things.first.id])

      result = Change.outstanding
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
      result = Change.outstanding

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
      result = Change.outstanding

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
      result = Change.outstanding
      change = result.detect { |change| change.page.id == new_child1.id }
      change.export.should == {
        :id => new_child1.id,
        :title => new_child1.title.value,
        :url => new_child1.path,
        :published_at => nil,
        :modified_at => new_child1.modified_at.httpdate,
        :depth => new_child1.depth,
        :side_effects => {},
        :dependent => [{
          :id => page1.id,
          :depth => page1.depth,
          :title => page1.title.value,
          :url => page1.path,
          :side_effects => {},
          :published_at => nil,
          :modified_at => page1.modified_at.httpdate,
        }]
      }
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

      old_slug = page1.slug
      page1.slug = "changed"
      page1.save

      result = Change.outstanding
      change = result.detect { |change| change.page.id == page1.id }
      change.export[:side_effects].should == {
        :slug => [{ :count => 1, :created_at => @now.httpdate, :old_value => old_slug, :new_value => "changed"}]
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

      page1.hide!

      result = Change.outstanding
      change = result.detect { |change| change.page.id == page1.id }
      change.export[:side_effects].should == {
        :visibility => [{ :count => 1, :created_at => @now.httpdate, :old_value => false, :new_value => true}]
      }
    end
  end
end
