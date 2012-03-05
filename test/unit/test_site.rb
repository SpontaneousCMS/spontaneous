# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class SiteTest < MiniTest::Spec
  include Spontaneous

  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Site" do
    setup do
      Content.delete
      class ::Page < Spontaneous::Page
        field :title
        box :subpages
      end
      class ::Piece < Spontaneous::Piece; end
    end

      teardown do
        Object.send(:remove_const, :Page)
        Object.send(:remove_const, :Piece)
      end

    context "contents" do
      setup do
        @root = ::Page.new
        @root.title = "Homepage"
        @page1_1 = ::Page.new(:slug => "page1-1")
        @page1_1.title = "Page 1 1"
        @page1_2 = ::Page.new(:slug => "page1-2")
        @page1_2.title = "Page 1 2"
        @page2_1 = ::Page.new(:slug => "page2-1")
        @page2_1.title = "Page 2 1"
        @page3_1 = ::Page.new(:slug => "page3-1")
        @page3_1.title = "Page 3 1"
        @page3_2 = ::Page.new(:slug => "page3-2")
        @page3_2.title = "Page 3 2"
        @page3_2.uid = "page3_2"

        @root.subpages << @page1_1
        @root.subpages << @page1_2
        @page1_1.subpages << @page2_1
        @page2_1.subpages << @page3_1
        @page2_1.subpages << @page3_2
        @root.save.reload
        @page1_1.save.reload
        @page1_2.save.reload
        @page2_1.save.reload
        @page3_1.save.reload
        @page3_2.save.reload
      end
      # context "site instance" do
      #   should "be unique" do
      #     i = Site.instance
      #     j = Site.instance
      #     i.should == j
      #     Site.count.should == 1
      #   end
      # should "be a singleton within a site cache" do
      #   o = nil
      #   Site.with_cache do
      #     i = Site.instance
      #     j = Site.instance
      #     i.object_id.should == j.object_id
      #     o = i.object_id
      #   end
      #   i = Site.instance
      #   i.object_id.should_not == o
      # end

      # end
      context 'mapping' do
        should "include the necessary details in the map" do
          @page3_2.map_entry.should == {
            :id => @page3_2.id,
            :title => "Page 3 2",
            :path => '/page1-1/page2-1/page3-2',
            :slug => 'page3-2',
            :type => 'Page',
            :type_id => ::Page.schema_id,
            :depth => 3,
            :children => {},
            :ancestors => [
              { :id => @root.id, :title => "Homepage", :path => '/', :slug => '', :type => 'Page', :type_id => ::Page.schema_id, :depth => 0, :children => 2 },
              { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :slug => 'page1-1', :type => 'Page', :type_id => ::Page.schema_id, :depth => 1, :children => 1 },
              { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :slug => 'page2-1', :type => 'Page', :type_id => ::Page.schema_id, :depth => 2, :children => 2 }
            ],
              :generation => { "Subpages" => [
                { :id => @page3_1.id, :title => "Page 3 1", :path => '/page1-1/page2-1/page3-1', :slug => 'page3-1', :type => 'Page', :type_id => ::Page.schema_id, :depth => 3, :children => 0 },
                { :id => @page3_2.id, :title => "Page 3 2", :path => '/page1-1/page2-1/page3-2', :slug => 'page3-2', :type => 'Page', :type_id => ::Page.schema_id, :depth => 3, :children => 0 }
            ] }
          }

          @page2_1.map_entry.should == {
            :id => @page2_1.id,
            :title => "Page 2 1",
            :path => '/page1-1/page2-1',
            :slug => 'page2-1',
            :type => 'Page',
            :type_id => ::Page.schema_id.to_s,
            :depth => 2,
            :children => {
              "Subpages" => [
                {:depth=>3,
                 :type=>"Page",
                 :type_id => ::Page.schema_id.to_s,
                 :children=>0,
                 :path=>"/page1-1/page2-1/page3-1",
                 :slug => 'page3-1',
                 :title=>"Page 3 1",
                 :id=>@page3_1.id},
                 {:depth=>3,
                  :type=>"Page",
                  :type_id => ::Page.schema_id.to_s,
                  :children=>0,
                  :path=>"/page1-1/page2-1/page3-2",
                  :slug => 'page3-2',
                  :title=>"Page 3 2",
                  :id=>@page3_2.id}]},
                  :ancestors => [
                    { :id => @root.id, :title => "Homepage", :path => '/', :slug => '',:type => 'Page', :type_id => ::Page.schema_id, :depth => 0, :children => 2 },
                    { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :slug => 'page1-1',:type => 'Page', :type_id => ::Page.schema_id, :depth => 1, :children => 1 }
                  ],
                    :generation => {"Subpages" => [
                      { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :slug => 'page2-1',:type => 'Page', :type_id => ::Page.schema_id, :depth => 2, :children => 2 }
                  ]}
          }
        end


        should "retrieve details of the root by default" do
          Site.map.should == Page.root.map_entry
        end

        should "retrieve the details of the children of any page" do
          Site.map(@root.id).should == Page.root.map_entry
          Site.map(@page3_2.id).should == @page3_2.map_entry
        end
      end
      context "page retrieval" do
        should "work with paths" do
          Site['/page1-1/page2-1'].should == @page2_1.reload
        end

        should "work with UIDs" do
          Site["page3_2"].should == @page3_2.reload
        end

        should "have a shortcut direct method on Site" do
          Site.page3_2.should == @page3_2.reload
        end

        should "return section pages in the right order" do
          Site.at_depth(0).should == @root
          Site.at_depth(:root).should == @root
          Site.at_depth(1).should == [@page1_1, @page1_2]
          Site.at_depth(:section).should == [@page1_1, @page1_2]
        end
      end
    end

    context "Structure modification times" do
      setup do
        State.delete
        # remove microseconds from time value
        @now = Time.at(Time.now.to_i)
      end

      should "just return the current time if no modifications have been made" do
        now = @now + 12
        Time.stubs(:now).returns(now)
        Site.modified_at.should == now
      end

      should "be updated when a page is added" do
        now = @now + 24
        Time.stubs(:now).returns(now)
        root = ::Page.create
        Time.stubs(:now).returns(now + 200)
        Site.modified_at.should == now
      end

      should "not be updated when a piece is added" do
        now1 = @now + 24
        Time.stubs(:now).returns(now1)
        root = ::Page.create
        now2 = @now + 240
        Time.stubs(:now).returns(now2)
        root.subpages << Piece.create
        Site.modified_at.should == now1
      end

      should "be updated when a page is deleted" do
        now1 = @now + 24
        Time.stubs(:now).returns(now1)
        root = ::Page.create
        now2 = @now + 48
        Time.stubs(:now).returns(now2)
        child = ::Page.new
        root.subpages << child
        root.save
        Site.modified_at.should == now2
        now3 = @now + 128
        Time.stubs(:now).returns(now3)
        child.destroy
        Site.modified_at.should == now3
      end

      should "not be updated when a piece is deleted" do
        now1 = @now + 24
        Time.stubs(:now).returns(now1)
        root = ::Page.create
        now2 = @now + 240
        Time.stubs(:now).returns(now2)
        piece = Piece.create
        root.subpages << piece
        Site.modified_at.should == now1
        now3 = @now + 480
        Time.stubs(:now).returns(now3)
        piece.destroy
        Site.modified_at.should == now1
      end
    end
  end
end
