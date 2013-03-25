# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Identify" do
  before do
    @base_dir = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/images'))
    @dimensions = [50, 67]
  end

  it "works for PNG24" do
    i = S::Media::Image.new(File.join(@base_dir, "size.png24"))
    i.format.must_equal :png
    i.dimensions.must_equal @dimensions
  end

  it "works for PNG8" do
    i = S::Media::Image.new(File.join(@base_dir, "size.png8"))
    i.format.must_equal :png
    i.dimensions.must_equal @dimensions
  end

  it "works for JPG" do
    i = S::Media::Image.new(File.join(@base_dir, "size.jpg"))
    i.format.must_equal :jpg
    i.dimensions.must_equal @dimensions
  end

  it "works for GIF" do
    i = S::Media::Image.new(File.join(@base_dir, "size.gif"))
    i.format.must_equal :gif
    i.dimensions.must_equal @dimensions
  end

  it "works for lossy WEBP" do
    i = S::Media::Image.new(File.join(@base_dir, "size.lossy.webp"))
    i.format.must_equal :webp
    i.dimensions.must_equal @dimensions
  end

  it "works for lossless WEBP" do
    i = S::Media::Image.new(File.join(@base_dir, "size.lossless.webp"))
    i.format.must_equal :webp
    i.dimensions.must_equal [386, 395]
  end


  it "works for extended WEBP" do
    i = S::Media::Image.new(File.join(@base_dir, "size.extended.webp"))
    i.format.must_equal :webp
    i.dimensions.must_equal [50, 38]
  end

  it "returns 0x0 for empty files" do
    Tempfile.open("emptyimagesize") do |file|
      i = S::Media::Image.new(file)
      i.dimensions.must_equal [0, 0]
      i.format.must_be_nil
    end
  end
end
