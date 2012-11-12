# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class ImageSizeTest < MiniTest::Spec
  context "Image size parser" do
    setup do
      @base_dir = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/images'))
      @dimensions = [50, 67]
    end

    should "work for PNG24" do
      S::ImageSize.read(File.join(@base_dir, "size.png24")).should == @dimensions
    end
    should "work for PNG8" do
      S::ImageSize.read(File.join(@base_dir, "size.png8")).should == @dimensions
    end
    should "work for JPG" do
      S::ImageSize.read(File.join(@base_dir, "size.jpg")).should == @dimensions
    end
    should "work for GIF" do
      S::ImageSize.read(File.join(@base_dir, "size.gif")).should == @dimensions
    end
  end
end

