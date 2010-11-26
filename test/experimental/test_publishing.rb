# encoding: UTF-8

require 'test_helper'


class PublishingTest < Test::Unit::TestCase

  context "data sources" do
    setup do
      Spontaneous.stubs(:database).returns(DB)
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
      Spontaneous.stubs(:database).returns(DB)

      # DB.logger = Logger.new($stdout)
      Content.delete
      10.times do |i|
        c = Content.create(:uid => i)
        2.times do |j|
          d = Content.create(:uid => "#{i}.#{j}")
          c << d
          2.times do |k|
            d << Content.create(:uid => "#{i}.#{j}.#{k}")
            d.save
          end
          c.save
        end
      end
    end

    teardown do
      Content.delete_all_revisions!
    end

    should "be deletable en masse" do
      tables = (1..10).map { |i| Content.revision_table(i) }
      tables.each do |t|
        DB.create_table(t){Integer :id}
      end
      tables.each do |t|
        DB.tables.include?(t.to_sym).should be_true
      end
      Content.delete_all_revisions!
      tables.each do |t|
        DB.tables.include?(t.to_sym).should be_false
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
        Content.filter(:depth => 0).limit(2).each do |c|
          c.destroy
        end
        source_revision_count = Content.count
      end

      Content.count.should == source_revision_count + 14

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
  end
end
