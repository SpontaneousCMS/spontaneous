# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Change" do

  before do
    @now = Time.now
    @site = setup_site

    Timecop.freeze(@now)
    @revision = 1

    Content.delete
    Spontaneous::State.delete

    class ::Page
      field :title, :string, :default => "New Page"
      box :things
    end

    class ::Piece
      box :things
    end
  end

  after do
    Timecop.return
    Content.delete_revision(@revision) rescue nil
    Content.delete_revision(@revision+1) rescue nil
    Content.delete
    @site.must_publish_all!(false)
    teardown_site
  end

  def outstanding_changes
    S::Change.outstanding(@site)
  end

  it "flag if the site has never been published" do
    root = Page.create(:title => "root")
    5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }
    result = outstanding_changes
    assert result.key?(:published_revision)
    result[:published_revision].must_equal 0
    assert result[:first_publish]
  end

  it "honors the site must_publish_all? flag" do
    @site.must_publish_all!
    root = Page.create(:title => "root")
    result = outstanding_changes
    result[:must_publish_all].must_equal true
  end


  it "list all newly created pages" do
    root = Page.create(:title => "root")
    root.save
    Content.publish(@revision)


    5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }

    result = outstanding_changes
    result.must_be_instance_of(Hash)

    pages = result[:changes]
    pages.must_be_instance_of(Array)
    pages.length.must_equal 5

    pages.map(&:class).must_equal [S::Change]*5

    Set.new(pages.map(&:page_id)).must_equal Set.new(root.things.map { |p| p.id })
  end

  it "not list new pieces as available for publish" do
    root = Page.create(:title => "root")
    Content.publish(@revision)
    root.reload
    root.things << Piece.new
    root.save.reload
    result = outstanding_changes[:changes]
    result.length.must_equal 1
    result.first.page.must_equal root
  end

  it "not list pages that have been published" do
    root = Page.create(:title => "root")

    Content.publish(@revision)

    5.times { |i| root.things << Page.create(:title => "Page #{i+1}") }
    root.save

    Content.publish(@revision+1, [root.id, root.things.first.id])

    result = outstanding_changes[:changes]
    result.length.must_equal 4
    Set.new(result.map(&:page_id).flatten).must_equal Set.new(root.things[1..-1].map(&:id))
  end

  it "group unpublished parents with their children" do
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
    result = outstanding_changes[:changes]

    result.length.must_equal 5

    id_groups = result.map { |change|
      [change.page.id, change.dependent.map(&:id)]
    }
    Set.new(id_groups).must_equal Set.new([
      [page1.id, []],
      [new_child1.id, [page1.id]],
      [new_parent.id, []],
      [new_child2.id, [new_parent.id ]],
      [new_child3.id, [new_parent.id, new_child2.id]]
    ])
  end

  it "successfully publish list of dependent pages" do
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
    result = outstanding_changes[:changes]

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

  it "provide page & dependency information in serializable format" do
    root = Page.create(:title => "root")

    Content.publish(@revision)

    root.reload
    page1 = Page.new(:title => "Page 1")
    root.things << page1
    new_child1  = Page.new(:title => "New Child 1")
    page1.things << new_child1
    root.save

    Content.publish(@revision+1, [root.id])
    result = outstanding_changes[:changes]
    change = result.detect { |change| change.page.id == new_child1.id }
    change.export.must_equal({
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
    })
  end

  it "order modified changes in reverse modification date order" do
    root = Page.create(:title => "root")

    Content.publish(@revision)

    root.reload
    page1 = Page.new(:title => "Page 1")
    root.things << page1
    root.save.reload
    page1.save.reload
    last = Time.now + 100
    Timecop.travel(last)
    new_child1  = Page.new(:title => "New Child 1")
    page1.things << new_child1
    page1.save
    new_child1.save
    result = outstanding_changes[:changes]
    assert result.first.modified_at > result.last.modified_at, "Change list in incorrect order"
  end

  it "provide information on side effects of publishing page with path changes" do
    root = Page.create(:title => "root")


    root.reload
    page1 = Page.new(:title => "Page 1")
    root.things << page1
    new_child1  = Page.new(:title => "New Child 1")
    page1.things << new_child1
    root.save
    new_child1.save

    Content.publish(@revision)
    page1.reload

    later = @now + 10
    Timecop.freeze(later)
    old_slug = page1.slug
    page1.slug = "changed"
    page1.save.reload

    result = outstanding_changes[:changes]

    change = result.detect { |change| change.page.id == page1.id }
    refute change.nil?
    change.export[:side_effects].must_equal({
      :slug => [{ :count => 1, :created_at => later.httpdate, :old_value => old_slug, :new_value => "changed"}]
    })
  end

  it "provide information on side effects of publishing page with visibility changes" do
    root = Page.create(:title => "root")


    root.reload
    page1 = Page.new(:title => "Page 1")
    root.things << page1
    new_child1  = Page.new(:title => "New Child 1")
    page1.things << new_child1
    root.save

    Content.publish(@revision)
    page1.reload

    later = @now + 10
    Timecop.freeze(later)
    page1.hide!


    result = outstanding_changes[:changes]
    change = result.detect { |change| change.page.id == page1.id }
    refute change.nil?
    change.export[:side_effects].must_equal({
      :visibility => [{ :count => 1, :created_at => later.httpdate, :old_value => false, :new_value => true}]
    })
  end

  it "provide information about any update locks that exist on a page" do
    Piece.field :async
    page = Page.create(:title => "page")


    piece = Piece.new

    page.things << piece
    page.save
    piece.save

    lock = Spontaneous::PageLock.create(:page_id => page.id, :content_id => piece.id, :field_id => piece.async.id, :description => "Update Lock")
    assert page.locked_for_update?
    result = outstanding_changes[:changes]
    change = result.detect { |change| change.page.id == page.id }
    change.export[:update_locks].must_equal [{
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
