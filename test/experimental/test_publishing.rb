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
end
