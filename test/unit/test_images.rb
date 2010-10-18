
require 'test_helper'

class FieldsTest < Test::Unit::TestCase
  include Spontaneous

  context "image fields" do

    setup do
      tmp = File.join(File.dirname(__FILE__), "../../tmp/media")
      Spontaneous.media_dir = tmp
      @tmp_dir = Pathname.new(tmp)
      @image_dir = @tmp_dir + "images"
      @image_dir.mkpath

      @src_image =  Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/images/rose.jpg"))
      @origin_image = @image_dir + "rose.jpg"
      @origin_image.make_link(@src_image.to_s) unless @origin_image.exist?

      class ::ImageField < FieldTypes::ImageField
        sizes :preview => { :width => 200 },
          :tall => { :height => 200 },
          :thumbnail => { :fit => [50, 50] },
          :icon => { :crop => [50, 50] }
      end

      @image = ImageField.new(:name => "photo")
      @image.value = @origin_image.to_s
    end

    teardown do
      Object.send(:remove_const, :ImageField)
      (@tmp_dir + "..").rmtree
    end

    should "have image dimension and filesize information" do
      @image.url.should == "/media/images/rose.jpg"
      @image.filesize.should == 102290
      @image.width.should == 600
      @image.height.should == 800
    end

    should "have access to the original uploaded file through field.original" do
      @image.url.should == "/media/images/rose.jpg"
      @image.original.width.should == @image.width
      @image.original.height.should == @image.height
      @image.original.filesize.should == @image.filesize
    end


    should "have a 'sizes' config option that generates resized versions" do
      assert_same_elements ImageField.size_definitions.keys, [:preview, :thumbnail, :icon, :tall]
    end

    should "persist attributes" do
      serialised = @image.serialize
      [:preview, :thumbnail, :icon, :tall].each do |size|
        serialised.key?(size).should be_true
        serialised[size][:url].should == "/media/images/rose.#{size}.jpg"
      end
      serialised[:preview][:width].should == 200
      serialised[:tall][:height].should == 200
      serialised[:thumbnail][:width].should == 38
      serialised[:thumbnail][:height].should == 50
      serialised[:icon][:width].should == 50
      serialised[:icon][:height].should == 50
    end

    context "resizing" do
      should "save the resized versions to the same directory" do
      end
      should "create new re-sized images when updated" do
      end

      should "honor the 'method' flag" do
      end
    end
  end
end
