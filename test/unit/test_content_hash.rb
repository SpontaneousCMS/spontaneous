# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# The guiding principle of the content hash is that if it renders the same then
# it should give the same content hash.
describe "Content Hash" do
  let(:page_class) { Page }
  let(:piece_class) { Piece }
  let(:root) { page_class.create }
  let(:piece) { piece_class.new }
  let(:hashes) { [] }
  let(:now) { Time.now }

  def assert_uniq_hashes(n)
    hashes.compact.uniq.length.must_equal n
  end

  before do
    Timecop.freeze(now)
    @site = setup_site
    page_class.field :title
  end

  after do
    Content.delete
    teardown_site
  end

  describe "Field" do
    before do
      page_class.field :title
    end
    let(:field) { root.title }

    it "has a different content hash for different value" do
      field.value = "original"
      hash1 = field.calculate_content_hash
      field.value = "different"
      hash2 = field.calculate_content_hash
      hash2.wont_equal hash1
    end

    it "returns the same hash if the value is reverted" do
      field.value = "original"
      hash1 = field.calculate_content_hash
      field.value = "different"
      field.value = "original"
      hash2 = field.calculate_content_hash
      hash2.must_equal hash1
    end
  end

  describe "Box" do
    let(:box) { piece.box1 }

    before do
      piece_class.field :field1
      piece_class.box :box1 do
        field :field1
        field :field2
      end
      piece.save
    end

    it "updates the hash for any field change" do
      hashes << box.calculate_content_hash
      box.field1 = "changed"
      hashes << box.calculate_content_hash
      box.field2 = "changed again"
      hashes << box.calculate_content_hash
      hashes.uniq.length.must_equal 3
    end

    it "updates the hash if an entry is added" do
      hashes << box.calculate_content_hash
      added = piece_class.new
      box << added
      hashes << box.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    describe "with entries" do
      before do
        hashes << box.calculate_content_hash
        @added1 = piece_class.create(field1: "added1")
        @added2 = piece_class.create(field1: "added2")
        box << @added1
        box << @added2
        hashes << box.calculate_content_hash
      end

      it "gives the same hash if new entries are deleted" do
        box.entries[0].destroy
        hashes << box.calculate_content_hash
        box.entries[0].destroy
        hashes << box.calculate_content_hash
        hashes.uniq.length.must_equal 3
        hashes.first.must_equal hashes.last
      end

      it "updates the hash if entries are reordered" do
        @added2.update_position(0)
        hashes << box.calculate_content_hash
        hashes.uniq.length.must_equal 3
      end

      it "preserves the hash if an identical entry is added as a replacement" do
        hashes.clear
        hashes << box.calculate_content_hash
        box.entries.last.destroy
        hashes << box.calculate_content_hash
        box << piece_class.create(field1: "added2")
        hashes << box.calculate_content_hash
        hashes.uniq.length.must_equal 2
        hashes.first.must_equal hashes.last
      end

      it "returns an empty hash if empty & has no fields" do
        piece_class.box :box2
        box = piece_class.new.box2
        box.calculate_content_hash.must_equal ""
      end
    end

    describe "PagePiece" do
      let(:box) { piece.box1 }
      let(:new_page) { page_class.create }

      before do
        root
        hashes << box.calculate_content_hash
      end

      it "should update the boxes content hash if a page is added" do
        box << new_page
        hashes << box.calculate_content_hash
        hashes.uniq.length.must_equal 2
      end

      it "should not change the box content hash if the page is updated" do
        box << new_page
        hashes << box.calculate_content_hash
        new_page.update(title: "something different")
        hashes << box.calculate_content_hash
        hashes.uniq.length.must_equal 2
      end
    end
  end

  describe "Piece" do
    before do
      piece_class.field :field1, default: "original"
      piece_class.field :field2, default: "original"
      piece_class.box :box1 do
        field :box_field1
      end
      piece_class.box :box2
      hashes << piece.calculate_content_hash
    end

    it "updates the hash for any field change" do
      piece.field1 = "changed"
      hashes << piece.calculate_content_hash
      piece.field2 = "changed again"
      hashes << piece.calculate_content_hash
      hashes.uniq.length.must_equal 3
    end

    it "updates the hash for any visibility change" do
      piece.hide!
      hashes << piece.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    it "has the same hash if the field values are the same" do
      piece.field1 = "changed 1"
      piece.field2 = "changed 2"
      hashes << piece.calculate_content_hash
      piece.field1 = "original"
      piece.field2 = "original"
      hashes << piece.calculate_content_hash
      hashes.uniq.length.must_equal 2
      hashes[0].must_equal hashes[2]
    end

    it "gives identical hashes for different entries with same type & fields" do
      one = piece_class.create(field1: "a", field2: "b")
      two = piece_class.create(field1: "a", field2: "b")
      one.calculate_content_hash.must_equal two.calculate_content_hash
    end

    it "is dependent on box hashes" do
      piece.box2.expects(:content_hash).returns("notverylikely")
      hashes << piece.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end
  end

  describe "Page" do
    let(:middle) { page_class.create(slug: 'middle', title: 'middle') }
    let(:page) { page_class.create(slug: 'child', title: 'original') }

    before do
      page_class.box :box1
      page_class.box :box2, generated: true
      root.box1 << middle
      middle.box1 << page
      root.save
      middle.save
      page.save
      hashes << page.calculate_content_hash
    end

    it "updates the content hash when field values change" do
      page.title = 'different'
      hashes << page.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    it "updates the hash for any visibility change" do
      page.hide!
      hashes << page.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    it "reverts the content hash when field values are reverted" do
      page.title = 'different'
      hashes << page.calculate_content_hash
      page.title = 'original'
      hashes << page.calculate_content_hash
      hashes.uniq.length.must_equal 2
      hashes.first.must_equal hashes.last
    end

    it "changes the content hash when the page path changes" do
      middle.update(slug: 'updated')
      hashes << page.reload.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    it "reverts the content hash when the page path reverts" do
      middle.update(slug: 'updated')
      hashes << page.reload.calculate_content_hash
      middle.update(slug: 'middle')
      hashes << page.reload.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    it "is dependent on box hashes" do
      page.box1.expects(:content_hash).returns('unlikely')
      hashes << page.calculate_content_hash
      hashes.uniq.length.must_equal 2
    end

    it "skips boxes marked as 'generated'" do
      page.box2.stubs(:calculate_content_hash).returns('unlikely')
      hashes << page.calculate_content_hash
      hashes.uniq.length.must_equal 1
    end
  end

  describe "Content Tree" do
    let(:middle) { page_class.create(slug: 'middle', title: 'middle') }
    let(:page) { page_class.create(slug: 'page', title: 'original') }
    let(:child) { piece_class.create(field1: 'child') }
    let(:grand_child) { piece_class.create(field1: 'grand child') }

    before do
      page_class.box :box1 do
        field :field1
      end
      piece_class.box :box1 do
        field :field1
      end
      piece_class.field :field1
      root.box1 << middle
      middle.box1 << page
      page.box1 << child
      child.box1 << grand_child
      [root, middle, page, child, grand_child].each do |content|
        content.save ; content.reload
      end
    end

    it "sets the content_hash attribute of pages on create" do
      page[:content_hash].must_equal page.calculate_content_hash
    end

    it "sets the content_hash attribute of pieces on create" do
      child[:content_hash].must_equal child.calculate_content_hash
    end

    it "sets the content_hash_changed to true" do
      child[:content_hash_changed].must_equal true
    end

    it "updates the page hash when page box fields change" do
      hashes << page.content_hash
      page.box1.field1 = "different"
      page.save
      hashes << page.reload[:content_hash]
      assert_uniq_hashes 2
    end

    it "updates the owning page hash when child pieces are updated" do
      hashes << page[:content_hash]
      child.field1 = "different"
      child.save
      hashes << page.reload[:content_hash]
      assert_uniq_hashes 2
    end

    it "updates the owning page hash when child pieces hidden" do
      hashes << page[:content_hash]
      child.hide!
      hashes << page.reload[:content_hash]
      assert_uniq_hashes 2
    end

    it "updates the owning page hash when boxes of child pieces are updated" do
      hashes << page.content_hash
      child.box1.field1 = "different"
      child.save
      hashes << page.reload[:content_hash]
      assert_uniq_hashes 2
    end

    it "updates the owning page hash when children of child pieces are updated" do
      hashes << page[:content_hash]
      grand_child.box1.field1 = "different"
      grand_child.save
      hashes << page.reload[:content_hash]
      assert_uniq_hashes 2
    end

    it "doesn't update the parent page hash when the child page is updated" do
      hashes << middle[:content_hash]
      grand_child.box1.field1 = "different"
      grand_child.save
      hashes << middle.reload[:content_hash]
      assert_uniq_hashes 1
    end
  end

  describe "content_hash_changed" do
    let(:page) { page_class.create(title: "something")}

    describe "before publishing" do
      it "sets the changed flag when content_hash differs" do
        page.update(title: "different")
        page.content_hash_changed.must_equal true
      end

      it "sets the content hash changed timestamp" do
        later = now + 3239
        Timecop.travel(later) do
          page.update(title: "different")
        end
        (page.content_hash_changed_at - later).must_be :<=, 1
      end

      it "keeps the flag set no matter what" do
        page.update(title: "different")
        page.content_hash_changed.must_equal true
        page.update(title: "something")
        page.content_hash_changed.must_equal true
      end
    end

    describe "after publishing" do
      before do
        page.update(published_content_hash: page.content_hash, content_hash_changed: false)
      end

      it "sets the changed flag when content_hash differs" do
        page.update(title: "different")
        page.content_hash_changed.must_equal true
      end

      it "sets the content hash changed timestamp" do
        later = now + 3239
        Timecop.travel(later) do
          page.update(title: "different")
        end
        (page.content_hash_changed_at - later).must_be :<=, 1
      end

      it "leaves the changed flag when content_hash differs" do
        page.update(title: "different")
        page.content_hash_changed.must_equal true
        page.update(title: "something")
        page.content_hash_changed.must_equal false
      end
    end
  end
end
