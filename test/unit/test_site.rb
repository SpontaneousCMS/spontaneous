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
    @page3_1 .title = "Page 3 1"
    @page3_2 = Page.new(:slug => "page3-2")
    @page3_2 .title = "Page 3 2"
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
      Page.root.map_entry.should == {
          :id => @root.id,
          :title => "Homepage",
          :path => '/',
          :type => 'Spontaneous.Page'
      }
    end
    should "retrieve details of the root by default" do
      Site.map.should == Page.root.map_entry
    end
    should "retrieve the details of the children of any page" do
      Site.map(@root.id).should == Page.root.map_children
    end
  end
end
