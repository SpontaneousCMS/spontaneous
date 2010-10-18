
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

      class ::ResizingImageField < FieldTypes::ImageField
        sizes :preview => { :width => 200 },
          :tall => { :height => 200 },
          :thumbnail => { :fit => [50, 50] },
          :icon => { :crop => [50, 50] }
      end

      @image = ResizingImageField.new(:name => "photo")
      @image.value = @origin_image.to_s
    end

    teardown do
      Object.send(:remove_const, :ResizingImageField)
      (@tmp_dir + "..").rmtree
    end

    should "have image dimension and filesize information" do
      @image.src.should == "/media/images/rose.jpg"
      @image.filesize.should == 102290
      @image.width.should == 600
      @image.height.should == 800
    end

    should "have access to the original uploaded file through field.original" do
      @image.src.should == "/media/images/rose.jpg"
      @image.original.width.should == @image.width
      @image.original.height.should == @image.height
      @image.original.filesize.should == @image.filesize
      @image.filepath.should == @origin_image.realpath.to_s
    end


    should "have a 'sizes' config option that generates resized versions" do
      assert_same_elements ResizingImageField.size_definitions.keys, [:preview, :thumbnail, :icon, :tall]
    end

    should "serialise attributes" do
      serialised = @image.serialize
      [:preview, :thumbnail, :icon, :tall].each do |size|
        serialised.key?(size).should be_true
        serialised[size][:src].should == "/media/images/rose.#{size}.jpg"
      end
      serialised[:preview][:width].should == 200
      serialised[:tall][:height].should == 200
      serialised[:thumbnail][:width].should == 38
      serialised[:thumbnail][:height].should == 50
      serialised[:icon][:width].should == 50
      serialised[:icon][:height].should == 50
      # pp serialised
    end

    context "attached to content" do
      setup do
        ResizingImageField.register
        class ::ContentWithImage < Content
          field :image, :resizing_image
        end
        @instance = ContentWithImage.new
        @instance.image = @origin_image.to_s
      end

      teardown do
        Object.send(:remove_const, :ContentWithImage)
      end

      should "persist attributes" do
        @instance.save
        @instance = ContentWithImage[@instance.id]
        @instance.image.thumbnail.src.should == "/media/images/rose.thumbnail.jpg"
        @instance.image.original.src.should == "/media/images/rose.jpg"
      end
    end
  end
end
