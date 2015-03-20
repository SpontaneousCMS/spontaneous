# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Revisions" do

  Revision = Spontaneous::Publishing::Revision

  start do
    site = setup_site
    let(:site) { site }

    Content.delete

    class Page
      field :title, :string, :default => "New Page"
      box :things
    end
    class Piece
      box :things
    end

    root = Page.create(:uid => "root")
    count = 0
    2.times do |i|
      c = Page.new(:uid => i)
      root.things << c
      count += 1
      2.times do |j|
        d = Piece.new(:uid => "#{i}.#{j}")
        c.things << d
        count += 1
        2.times do |k|
          d.things << Page.new(:uid => "#{i}.#{j}.#{k}")
          d.save
          count += 1
        end
      end
      c.save
    end
    root.save

    Revision.history_dataset(Content).delete
    Revision.archive_dataset(Content).delete
    Revision.delete_all(Content)

    let(:root) { root }
  end

  finish do
    Object.send(:remove_const, :Page) rescue nil
    Object.send(:remove_const, :Piece) rescue nil
    Content.delete
    teardown_site
  end

  before do
    @now = Time.now
    stub_time(@now)
  end

  after do
    Revision.delete_all(Content)
  end

  describe "data sources" do

    it "have the right names" do
      Content.revision_table(23).must_equal :'__r00023_content'
      Content.revision_table(nil).must_equal :'content'
    end

    it "be recognisable" do
      refute Content.revision_table?('content')
      assert Content.revision_table?('__r00023_content')
      refute Content.revision_table?('__r00023_not')
      refute Content.revision_table?('subscribers')
    end

    it "be switchable within blocks" do
      Content.with_revision(23) do
        Content.revision.must_equal 23
        Content.mapper.current_revision.must_equal 23
      end
      Content.mapper.current_revision.must_be_nil
    end

    it "know which revision is active" do
      Content.with_revision(23) do
        Content.revision.must_equal 23
      end
    end

    it "understand with_editable" do
      Content.with_revision(23) do
        Content.mapper.current_revision.must_equal 23
        Content.with_editable do
          Content.mapper.current_revision.must_be_nil
        end
      end
    end

    it "understand with_published" do
      site.stubs(:published_revision).returns(99)
      Content.with_published(site) do
        Content.mapper.current_revision.must_equal 99
      end
    end

    it "be stackable" do
      Content.with_revision(23) do
        Content.mapper.current_revision.must_equal 23
        Content.with_revision(24) do
          Content.mapper.current_revision.must_equal 24
        end
      end
    end

    it "reset datasource after an exception" do
      begin
        Content.with_revision(23) do
          Content.mapper.current_revision.must_equal 23
          raise "Fail"
        end
      rescue Exception
      end
      Content.mapper.current_revision.must_be_nil
    end

    it "read revision from the environment if present" do
      ENV["SPOT_REVISION"] = '1001'
      Content.with_published(site) do
        Content.mapper.current_revision.must_equal 1001
      end
      ENV.delete("SPOT_REVISION")
    end

    describe "subclasses" do
      before do
        class ::Subclass < Page; end
      end

      after do
        Object.send(:remove_const, :Subclass)
      end

      it "set all subclasses to use the same dataset" do
        Content.with_revision(23) do
          Subclass.revision.must_equal 23
          Subclass.mapper.current_revision.must_equal 23
          # piece wasn't loaded until this point
          Piece.mapper.current_revision.must_equal 23
        end
      end
    end
  end

  describe "content revisions" do
    before do
      @revision = 1
    end

    after do
      # Revision.delete_all(Content)
    end

    it "be testable for existance" do
      refute Content.revision_exists?(@revision)
      Revision.create(Content, @revision)
      assert Revision.exists?(Content, @revision)
    end

    it "not be deletable if their revision is nil" do
      Revision.delete(Content, nil)
      assert Content.db.table_exists?(:content)
    end

    it "be deletable en masse" do
      revisions = (1..10).to_a
      tables = revisions.map { |i| Content.revision_table(i).to_sym }

      revisions.each do |r|
        Content.history_dataset.insert(:revision => r, :uid => "revision-#{r}")
        Content.archive_dataset.insert(:revision => r, :uid => "archive-#{r}")
      end

      Content.history_dataset.count.must_equal 10
      Content.archive_dataset.count.must_equal 10

      tables.each do |t|
        DB.create_table(t){Integer :id} rescue nil
      end

      tables.each do |t|
        assert DB.tables.include?(t)
      end

      Revision.delete_all(Content)

      tables.each do |t|
        refute DB.tables.include?(t)
      end

      Content.history_dataset.count.must_equal 0
      Content.archive_dataset.count.must_equal 0
    end

    it "be creatable from current content" do
      refute DB.tables.include?(Content.revision_table(@revision).to_sym)
      Revision.create(Content, @revision)
      assert DB.tables.include?(Content.revision_table(@revision).to_sym)
      count = Content.count
      Content.with_revision(@revision) do
        Content.count.must_equal count
        Content.all.each do |published|
          published.revision.must_equal @revision
          Content.with_editable do
            e = Content[published.id]
            assert_content_equal(e, published, :revision)
            e.revision.must_be_nil
          end
        end
      end
      Content.history_dataset(@revision).count.must_equal count
      Content.history_dataset.select(:revision).group(:revision).all.must_equal [{:revision => 1}]
      Content.archive_dataset(@revision).count.must_equal count
      Content.archive_dataset.select(:revision).group(:revision).all.must_equal [{:revision => 1}]
    end

    it "adds an index for the primary key" do
      Revision.create(Content, @revision)
      pk = Content.primary_key
      published_indexes = DB.indexes(Content.revision_table(@revision))
      pk_index = published_indexes.detect { |name, index| index[:columns] == [pk] }
      pk_index.wont_equal nil
      name, options = pk_index
      options[:unique].must_equal true
    end

    it "have the correct indexes" do
      Revision.create(Content, @revision)
      content_indexes = DB.indexes(:content)
      # filter out the pk index as the DB::indexes call doesn't include it
      published_indexes = DB.indexes(Content.revision_table(@revision)).reject { |name, index| index[:columns] == [:id] }
      # made slightly complex by the fact that the index names depend on the table names
      # (which are different)
      assert_has_elements published_indexes.values, content_indexes.values
    end

    it "only be kept until a new revision is available" do
      (0..2).each do |r|
        Revision.create(Content, @revision+r)
        Content.history_dataset(@revision+r).count.must_equal 15
        Content.archive_dataset(@revision+r).count.must_equal 15
      end
      Content.revision_tables.must_equal [:__r00001_content, :__r00002_content, :__r00003_content]
      Revision.cleanup(Content, @revision+2, 2)
      Content.revision_tables.must_equal [:__r00003_content]
      Content.history_dataset(@revision).count.must_equal 0
      Content.archive_dataset(@revision).count.must_equal 15
      Content.history_dataset(@revision+2).count.must_equal 15
    end


    describe "incremental publishing" do
      before do
        @initial_revision = 1
        @final_revision = 2
        Revision.create(Content, @initial_revision)
      end

      it "duplicate changes to only a single item" do
        editable1 = Content.first(:uid => '1.0')
        editable1.label.must_be_nil
        editable1.label = "published"
        editable1.save
        editable2 = Content.first(:uid => '1.1')
        editable2.label = "unpublished"
        editable2.save
        editable2.reload
        Revision.patch(Content, @final_revision, [editable1.id])
        editable1.reload
        Content.with_revision(@final_revision) do
          published = Content.first :id => editable1.id
          unpublished = Content.first :id => editable2.id
          assert_content_equal(published, editable1, :revision)
          assert_content_unequal(unpublished, editable2, :revision)
        end
      end

      it "publish additions to contents of a page" do
        editable1 = Content.first(:uid => '0')
        new_content = Piece.new(:uid => "new")

        editable1.things << new_content
        editable1.save
        Revision.patch(Content, @final_revision, [editable1.id])
        new_content.reload
        editable1.reload
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_content.id]
          assert_content_equal(published2, new_content, :revision)
          assert_content_equal(published1, editable1, :revision)
        end
      end

      it "publish deletions to contents of page" do
        editable1 = Content.first(:uid => '0')
        deleted = editable1.contents.first
        editable1.contents.first.destroy
        Revision.patch(Content, @final_revision, [editable1.id])
        editable1.reload
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          assert_content_equal(published1, editable1, :revision)
          Content[deleted.id].must_be_nil
        end
      end

      it "not publish page additions" do
        editable1 = Content.first(:uid => '0')
        new_page = Page.new(:uid => "new")
        editable1.things << new_page
        editable1.save
        new_page.save
        Revision.patch(Content, @final_revision, [editable1.id])
        new_page.reload
        editable1.reload
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_page.id]
          published2.must_be_nil
          assert_content_equal(published1, editable1, :revision)
        end
      end

      it "not publish changes to existing pages unless explicitly asked" do
        editable1 = Content.first(:uid => '0')
        editable1.things << Piece.new(:uid => "added")
        editable1.save
        editable2 = Content.first(:uid => '0.0.0')
        new_content = Piece.new(:uid => "new")
        editable2.things << new_content
        editable2.save
        Revision.patch(Content, @final_revision, [editable1.id])
        editable1.reload
        editable2.reload
        new_content.reload
        Content.with_revision(@final_revision) do
          published1 = Content.first :id => editable1.id
          Content.first(:uid => "added").wont_be_nil
          published3 = Content.first :id => editable2.id
          assert_content_equal(published1, editable1, :revision)
          assert_content_unequal(published3, editable2, :revision)
          published3.uid.wont_equal "new"
        end
        Revision.patch(Content, @final_revision+1, [editable2.id])
        editable1.reload
        editable2.reload
        new_content.reload
        Content.with_revision(@final_revision+1) do
          published1 = Content.first :id => editable1.id
          assert_content_equal(published1, editable1, :revision)
          published2 = Content.first :id => editable2.id
          assert_content_equal(published2, editable2, :revision)
          published3 = Content.first :id => editable2.contents.first.id
          # published3.must_equal editable2.contents.first
          assert_content_equal(published3, editable2.contents.first, :revision)
        end
      end

      it "insert an entry value into the parent of a newly added page when that page is published" do
        editable1 = Content.first(:uid => '0')
        new_page = Page.new(:uid => "new")
        editable1.things << new_page
        editable1.save
        new_page.save
        Revision.patch(Content, @final_revision, [new_page.id])
        new_page.reload
        editable1.reload
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_page.id]
          assert_content_equal(published2, new_page, :revision)
          editable1.boxes.flat_map(&:ids).must_equal published1.boxes.flat_map(&:ids)
        end
      end

      it "choose a sensible position for entry into the parent of a newly added page" do
        editable1 = Content.first(:uid => '0')
        new_page1 = Page.new(:uid => "new1")
        new_page2 = Page.new(:uid => "new2")
        editable1.things << new_page1
        editable1.things << new_page2
        editable1.save
        new_page1.save
        new_page2.save
        Revision.patch(Content, @final_revision, [new_page2.id])
        new_page1.reload
        new_page2.reload
        editable1.reload
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_page1.id]
          published3 = Content[new_page2.id]
          published2.must_be_nil
          assert_content_equal(published3, new_page2, :revision)
          editable1.boxes.flat_map(&:ids).reject{ |e| e == new_page1.id }.must_equal published1.boxes.flat_map(&:ids)
        end
      end

      it "not duplicate entries when publishing pages for the first time" do
        editable1 = Content.first(:uid => '0')
        new_page1 = Page.new(:uid => "new1")
        new_page2 = Page.new(:uid => "new2")
        editable1.things << new_page1
        editable1.things << new_page2
        editable1.save
        new_page1.save
        new_page2.save
        Revision.patch(Content, @final_revision, [editable1.id, new_page2.id])
        new_page1.reload
        new_page2.reload
        editable1.reload
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_page1.id]
          published3 = Content[new_page2.id]
          published2.must_be_nil
          assert_content_equal(published3, new_page2, :revision)
          assert_content_equal(published1, editable1, :revision)
        end
      end

      it "remove deleted pages from the published content" do
        page = Page.first :uid => "0"
        piece = page.things.first
        child = piece.things.first
        page.things.first.destroy
        Revision.patch(Content, @final_revision, [page.id])

        Content.with_revision(@final_revision) do
          published_parent = Content[page.id]
          published_piece = Content[piece.id]
          published_page = Content[child.id]
          published_parent.must_equal page.reload
          published_piece.must_be_nil
          published_page.must_be_nil
        end
      end
    end
  end

  describe "reverting changes" do
    it "reverts page fields"
    it "reverts piece fields"
    it "removes added pieces"
    it "restores removed pieces"
    it "restores deleted pages"
  end

  describe "content hashes" do
    before do
      @revision = 1
      Revision.delete(Content, @revision+1)
    end
    it "starts with a published_content_hash of nil" do
      first = Content.first
      first.published_content_hash.must_equal nil
      first.content_hash.wont_equal nil
      first.content_hash.length.must_equal 32
    end

    it "sets the published_content_hash on first publish" do
      first = Content.first
      content_hash = first.content_hash
      first.reload.published_content_hash.must_be_nil
      first.content_hash_changed.must_equal true
      Revision.create(Content, @revision)
      first.reload.published_content_hash.must_equal  content_hash
      first.content_hash_changed.must_equal false
      Content.with_editable do
        first.reload.published_content_hash.must_equal content_hash
        first.content_hash_changed.must_equal false
      end
      Content.with_revision(@revision) do
        first.reload.published_content_hash.must_equal content_hash
      end
    end

    it "updates the published_content_hash on later publishes" do
      first = Page.first
      content_hash = first.content_hash
      Revision.create(Content, @revision)
      first.reload.published_content_hash.must_equal content_hash
      first.update(title: "not the same")
      content_hash2 = first.content_hash
      content_hash2.wont_equal content_hash
      added = Page.create
      added.published_content_hash.must_be_nil
      added.content_hash_changed.must_equal true
      content_hash_added = added.content_hash
      Revision.create(Content, @revision+1)
      first.reload.published_content_hash.must_equal content_hash2
      first.content_hash_changed.must_equal false
      Content.with_editable do
        c = Page.first :id => added.id
        c.published_content_hash.must_equal content_hash_added
        c.content_hash_changed.must_equal false
        c = Page.first :id => first.id
        c.published_content_hash.must_equal content_hash2
        c.content_hash_changed.must_equal false
      end
      Content.with_revision(@revision+1) do
        c = Page.first :id => added.id
        c.published_content_hash.must_equal content_hash_added
        c.content_hash_changed.must_equal false
        c = Page.first :id => first.id
        c.published_content_hash.must_equal content_hash2
        c.content_hash_changed.must_equal false
      end
    end

    it "doesn't set published_content_hash for items not published" do
      Revision.create(Content, @revision)
      page = Page.first
      page.title = "changed"
      page.save
      page.content_hash_changed.must_equal true
      content_hash = page.content_hash
      added = Page.create
      added.published_content_hash.must_be_nil
      added.reload.content_hash_changed.must_equal true
      Revision.patch(Content, @revision+1, [page])
      page.reload.published_content_hash.must_equal content_hash
      page.content_hash_changed.must_equal false
      added.reload.published_content_hash.must_be_nil
      added.reload.content_hash_changed.must_equal true
    end

    it "doesn't set published_content_hash if exception raised in passed block" do
      Content.first.published_content_hash.must_be_nil
      begin
        Revision.create(Content, @revision) do
          raise "Fail"
        end
      rescue Exception; end
      Content.first.published_content_hash.must_be_nil
    end
  end

  describe "publication timestamps" do
    before do
      @revision = 1
      Revision.delete(Content, @revision+1)
    end

    it "set correct timestamps on first publish" do
      first = Content.first
      first.reload.first_published_at.must_be_nil
      first.reload.last_published_at.must_be_nil
      Revision.create(Content, @revision)
      first.reload.first_published_at.to_i.must_equal @now.to_i
      first.reload.last_published_at.to_i.must_equal @now.to_i
      first.reload.first_published_revision.must_equal @revision
      Content.with_editable do
        first.reload.first_published_at.to_i.must_equal @now.to_i
        first.reload.last_published_at.to_i.must_equal @now.to_i
        first.reload.first_published_revision.must_equal @revision
      end
      Content.with_revision(@revision) do
        first.reload.first_published_at.to_i.must_equal @now.to_i
        first.reload.last_published_at.to_i.must_equal @now.to_i
        first.reload.first_published_revision.must_equal @revision
      end
    end

    it "set correct timestamps on later publishes" do
      first = Content.first
      first.first_published_at.must_be_nil
      Revision.create(Content, @revision)
      first.reload.first_published_at.to_i.must_equal @now.to_i
      c = Page.create
      c.first_published_at.must_be_nil
      stub_time(@now + 100)
      Revision.create(Content, @revision+1)
      first.reload.first_published_at.to_i.must_equal @now.to_i
      first.reload.last_published_at.to_i.must_equal @now.to_i + 100
      Content.with_editable do
        c = Content.first :id => c.id
        c.first_published_at.to_i.must_equal @now.to_i + 100
      end
      Content.with_revision(@revision+1) do
        c = Content.first :id => c.id
        c.first_published_at.to_i.must_equal @now.to_i + 100
      end
    end

    it "not set publishing date for items not published" do
      Revision.create(Content, @revision)
      page = Content.first
      page.uid = "fish"
      page.save
      added = Content.create
      added.first_published_at.must_be_nil
      Revision.patch(Content, @revision+1, [page])
      page.first_published_at.to_i.must_equal @now.to_i
      added.first_published_at.must_be_nil
      added.last_published_at.must_be_nil
    end

    it "not set publishing dates if exception raised in passed block" do
      Content.first.first_published_at.must_be_nil
      begin
        Revision.create(Content, @revision) do
          raise "Fail"
        end
      rescue Exception; end
      Content.first.first_published_at.must_be_nil
    end

    it "delete revision tables if exception raised in passed block" do
      refute Revision.exists?(Content, @revision)
      begin
        Revision.create(Content, @revision) do
          assert Revision.exists?(Content, @revision)
          Content.revision.must_equal @revision
          raise "Fail"
        end
      rescue Exception; end
      refute Revision.exists?(Content, @revision)
    end

    it "always publish all if no previous revisions exist" do
      page = Content.first
      Content.filter(:first_published_at => nil).count.must_equal Content.count
      Revision.patch(Content, @revision, [page])
      Content.filter(:first_published_at => nil).count.must_equal 0
    end
  end
end
