# encoding: UTF-8

require 'test_helper'


class SiteTest < Test::Unit::TestCase
  include Spontaneous
  def setup
    Content.delete
    @root = Page.new
    @root.title = "Homepage"
    @page1_1 = Page.new(:slug => "page1-1")
    @page1_1.title = "Page 1 1"
    @page1_2 = Page.new(:slug => "page1-2")
    @page1_2.title = "Page 1 2"
    @page2_1 = Page.new(:slug => "page2-1")
    @page2_1.title = "Page 2 1"
    @page3_1 = Page.new(:slug => "page3-1")
    @page3_1.title = "Page 3 1"
    @page3_2 = Page.new(:slug => "page3-2")
    @page3_2.title = "Page 3 2"
    @page3_2.uid = "page3_2"

    @root << @page1_1
    @root << @page1_2
    @page1_1 << @page2_1
    @page2_1 << @page3_1
    @page2_1 << @page3_2
    @root.save
    @page1_1.save
    @page1_2.save
    @page2_1.save
    @page3_1.save
    @page3_2.save
  end
  context "site instance" do
    should "be unique" do
      i = Site.instance
      j = Site.instance
      i.should == j
      Site.count.should == 1
    end
    should "be a singleton within a site cache" do
      o = nil
      Site.with_cache do
        i = Site.instance
        j = Site.instance
        i.object_id.should == j.object_id
        o = i.object_id
      end
      i = Site.instance
      i.object_id.should_not == o
    end

  end
  context 'Site mapping' do
    should "include the necessary details in the map" do
      @page3_2.map_entry.should == {
          :id => @page3_2.id,
          :title => "Page 3 2",
          :path => '/page1-1/page2-1/page3-2',
          :type => 'Spontaneous.Page',
          :depth => 3,
          :children => [],
          :ancestors => [
            { :id => @root.id, :title => "Homepage", :path => '/', :type => 'Spontaneous.Page', :depth => 0, :children => 2 },
            { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :type => 'Spontaneous.Page', :depth => 1, :children => 1 },
            { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :type => 'Spontaneous.Page', :depth => 2, :children => 2 }
          ],
          :generation => [
            { :id => @page3_1.id, :title => "Page 3 1", :path => '/page1-1/page2-1/page3-1', :type => 'Spontaneous.Page', :depth => 3, :children => 0 },
            { :id => @page3_2.id, :title => "Page 3 2", :path => '/page1-1/page2-1/page3-2', :type => 'Spontaneous.Page', :depth => 3, :children => 0 }
          ],
          :children => []
      }

      @page2_1.map_entry.should == {
          :id => @page2_1.id,
          :title => "Page 2 1",
          :path => '/page1-1/page2-1',
          :type => 'Spontaneous.Page',
          :depth => 2,
          :children => [{:depth=>3,
                         :type=>"Spontaneous.Page",
                         :children=>0,
                         :path=>"/page1-1/page2-1/page3-1",
                         :title=>"Page 3 1",
                         :id=>@page3_1.id},
                         {:depth=>3,
                          :type=>"Spontaneous.Page",
                          :children=>0,
                          :path=>"/page1-1/page2-1/page3-2",
                          :title=>"Page 3 2",
                          :id=>@page3_2.id}],
          :ancestors => [
            { :id => @root.id, :title => "Homepage", :path => '/', :type => 'Spontaneous.Page', :depth => 0, :children => 2 },
            { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :type => 'Spontaneous.Page', :depth => 1, :children => 1 }
          ],
          :generation => [
            { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :type => 'Spontaneous.Page', :depth => 2, :children => 2 }
          ]
      }
    end

    should ""

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
  end
end
