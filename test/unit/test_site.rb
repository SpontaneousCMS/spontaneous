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
  context 'Site mapping' do
    should "include the necessary details in the map" do
      @page3_2.map_entry.should == {
          :id => @page3_2.id,
          :title => "Page 3 2",
          :path => '/page1-1/page2-1/page3-2',
          :type => 'Spontaneous.Page',
          :ancestors => [
            { :id => @root.id, :title => "Homepage", :path => '/', :type => 'Spontaneous.Page' },
            { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :type => 'Spontaneous.Page' },
            { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :type => 'Spontaneous.Page' }
          ],
          :generation => [
            { :id => @page3_1.id, :title => "Page 3 1", :path => '/page1-1/page2-1/page3-1', :type => 'Spontaneous.Page' },
            { :id => @page3_2.id, :title => "Page 3 2", :path => '/page1-1/page2-1/page3-2', :type => 'Spontaneous.Page' }
          ],
          :children => []
      }

      @page2_1.map_entry.should == {
          :id => @page2_1.id,
          :title => "Page 2 1",
          :path => '/page1-1/page2-1',
          :type => 'Spontaneous.Page',
          :ancestors => [
            { :id => @root.id, :title => "Homepage", :path => '/', :type => 'Spontaneous.Page' },
            { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :type => 'Spontaneous.Page' }
          ],
          :generation => [
            { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :type => 'Spontaneous.Page' }
          ],
          :children => [
            { :id => @page3_1.id, :title => "Page 3 1", :path => '/page1-1/page2-1/page3-1', :type => 'Spontaneous.Page' },
            { :id => @page3_2.id, :title => "Page 3 2", :path => '/page1-1/page2-1/page3-2', :type => 'Spontaneous.Page' }
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
