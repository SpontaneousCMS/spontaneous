# encoding: UTF-8

require 'test_helper'


class PublishingTest < Test::Unit::TestCase

  context "data sources" do
    setup do
      Spontaneous.database = DB
    end

    should "have the right names" do
      Content.revision_table(23).should == '__r00023_content'
      Content.revision_table(nil).should == 'content'
    end

    should "be recognisable" do
      Content.revision_table?('content').should be_false
      Content.revision_table?('__r00023_content').should be_true
      Content.revision_table?('__r00023_not').should be_false
      Content.revision_table?('subscribers').should be_false
    end

    should "be switchable within blocks" do
      Content.dataset.should be_content_revision
      Content.with_revision(23) do
        Content.revision.should ==23
        Content.dataset.should be_content_revision(23)
      end
      Content.dataset.should  be_content_revision
      Content.revision.should be_nil
    end

    should "know which revision is active" do
      Content.with_revision(23) do
        Content.revision.should == 23
      end
    end

    should "be switchable without blocks" do
      Content.with_revision(23)
      Content.dataset.should be_content_revision(23)
      Content.reset_revision
      Content.dataset.should be_content_revision
    end

    should "understand the with_editable" do
      Content.with_revision(23) do
        Content.dataset.should be_content_revision(23)
        Content.with_editable do
          Content.dataset.should be_content_revision
        end
        Content.dataset.should be_content_revision(23)
      end
      Content.dataset.should be_content_revision
    end

    should "understand with_published" do
      Site.stubs(:published_revision).returns(99)
      Content.with_published do
        Content.dataset.should be_content_revision(99)
        Content.with_editable do
          Content.dataset.should be_content_revision
        end
        Content.dataset.should be_content_revision(99)
      end
      Content.dataset.should be_content_revision
    end

    should "be stackable" do
      Content.dataset.should be_content_revision
      Content.with_revision(23) do
        Content.dataset.should be_content_revision(23)
        Content.with_revision(24) do
          Content.dataset.should be_content_revision(24)
        end
        Content.dataset.should be_content_revision(23)
      end
      Content.dataset.should be_content_revision
    end

    should "reset datasource after an exception" do
      Content.dataset.should be_content_revision
      begin
        Content.with_revision(23) do
          Content.dataset.should be_content_revision(23)
          raise Exception.new
        end
      rescue Exception
      end
      Content.dataset.should be_content_revision
    end

    context "subclasses" do
      setup do
        class ::Subclass < Page; end
      end

      teardown do
        Object.send(:remove_const, :Subclass)
      end

      should "set all subclasses to use the same dataset" do
        Content.with_revision(23) do
          Subclass.revision.should ==23
          Subclass.dataset.should be_content_revision(23, 'Subclass')
          # facet wasn't loaded until this point
          Facet.dataset.should  be_content_revision(23, 'Spontaneous::Facet')
          Facet.revision.should == 23
        end
        Subclass.dataset.should  be_content_revision(nil, 'Subclass')
        Facet.dataset.should  be_content_revision(nil, 'Spontaneous::Facet')
      end
    end
  end

  context "content revisions" do
    setup do
      Spontaneous.database = DB

      # DB.logger = Logger.new($stdout)
      Content.delete

      2.times do |i|
        c = Page.new(:uid => i)
        2.times do |j|
          d = Content.new(:uid => "#{i}.#{j}")
          c << d
          2.times do |k|
            d << Page.new(:uid => "#{i}.#{j}.#{k}")
            d.save
          end
        end
        c.save
      end
    end

    teardown do
      Content.delete_all_revisions!
      DB.logger = nil
    end

    should "be deletable en masse" do
      tables = (1..10).map { |i| Content.revision_table(i).to_sym }
      tables.each do |t|
        DB.create_table(t){Integer :id}
      end
      tables.each do |t|
        DB.tables.include?(t).should be_true
      end
      Content.delete_all_revisions!
      tables.each do |t|
        DB.tables.include?(t).should be_false
      end
    end

    should "be creatable from current content" do
      revision = 1
      DB.tables.include?(Content.revision_table(revision).to_sym).should be_false
      Content.create_revision(revision)
      DB.tables.include?(Content.revision_table(revision).to_sym).should be_true
      count = Content.count
      Content.with_revision(revision) do
        Content.count.should == count
        Content.all.each do |published|
          Content.with_editable do
            e = Content[published.id]
            e.should == published
          end
        end
      end
    end

    should "be creatable from any revision" do
      revision = 2
      source_revision = 1
      source_revision_count = nil

      Content.create_revision(source_revision)

      Content.with_revision(source_revision) do
        Content.filter(:depth => 0).limit(1).each do |c|
          c.destroy
        end
        source_revision_count = Content.count
      end

      Content.count.should == source_revision_count + 7

      Content.create_revision(revision, source_revision)

      Content.with_revision(revision) do
        Content.count.should == source_revision_count
        Content.all.each do |published|
          Content.with_revision(source_revision) do
            e = Content[published.id]
            e.should == published
          end
        end
      end
    end

    should "have the correct indexes" do
      revision = 1
      Content.create_revision(revision)
      content_indexes = DB.indexes(:content)
      published_indexes = DB.indexes(Content.revision_table(revision))
      # made slightly complex by the fact that the index names depend on the table names
      # (which are different)
      assert_same_elements published_indexes.values, content_indexes.values
    end


    context "incremental publishing" do
      setup do
        @initial_revision = 1
        @final_revision = 2
        Content.create_revision(@initial_revision)
        # DB.logger = Logger.new($stdout)
      end

      teardown do
        DB.logger = nil
      end

      should "duplicate changes to only a single item" do
        editable1 = Content.first(:uid => '1.0')
        editable1.label.should be_nil
        editable1.label = "published"
        editable1.save
        # editable1.reload
        editable2 = Content.first(:uid => '1.1')
        editable2.label = "unpublished"
        editable2.save
        # editable2.reload
        Content.publish(@final_revision, @initial_revision, [editable1.id])

        Content.with_revision(@final_revision) do
          published = Content[editable1.id]
          unpublished = Content[editable2.id]
          published.should == editable1
          unpublished.should_not == editable2
        end
      end

      should "publish additions to contents of a page" do
        editable1 = Content.first(:uid => '0')
        new_content = Content.new(:uid => "new")

        editable1 << new_content
        editable1.save
        new_content.reload
        editable1.reload
        Content.publish(@final_revision, @initial_revision, [editable1.id])
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_content.id]
          published2.should == new_content
          published1.should == editable1
        end
      end

      should "publish deletions to contents of page" do
        editable1 = Content.first(:uid => '0')
        deleted = editable1.entries.first.target
        editable1.entries.first.destroy
        editable1.reload
        Content.publish(@final_revision, @initial_revision, [editable1.id])
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published1.should == editable1
          Content[deleted.id].should be_nil
        end
      end

      should "publish additions to child pages" do
        editable1 = Content.first(:uid => '0')
        new_page = Page.new(:uid => "new")
        slot = editable1.entries.first
        slot << new_page
        editable1.save
        slot.save
        new_page.save
        new_page.reload
        editable1.reload
        slot.reload
        Content.publish(@final_revision, @initial_revision, [editable1.id])
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          published2 = Content[new_page.id]
          published3 = Content[slot.id]
          published1.should == editable1
          published2.should == new_page
          published3.should == slot
        end
      end

      should "not publish changes to existing pages unless explicitly asked" do
        editable1 = Content.first(:uid => '0')
        editable1 << Content.new(:uid => "added")
        editable1.save
        editable1.reload
        editable2 = Content.first(:uid => '0.0.0')
        new_content = Content.new(:uid => "new")
        editable2 << new_content
        editable2.save
        editable2.reload
        new_content.reload
        Content.publish(@final_revision, @initial_revision, [editable1.id])
        Content.with_revision(@final_revision) do
          published1 = Content[editable1.id]
          Content.first(:uid => "added").should_not be_nil
          published3 = Content[editable2.id]
          published1.should == editable1
          published3.should_not == editable2
          published3.uid.should_not == "new"
        end
        Content.publish(@final_revision+1, @final_revision, [editable2.id])
        Content.with_revision(@final_revision+1) do
          published1 = Content[editable1.id]
          published1.should == editable1
          published3 = Content[editable2.id]
          published3.should == editable2
          published4 = Content[editable2.entries.first.id]
          published4.should == editable2.entries.first
        end
      end
    end


  end
end
