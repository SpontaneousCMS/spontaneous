# encoding: UTF-8


require 'test_helper'
# require 'openssl'

class ImagesTest < Test::Unit::TestCase
  include Spontaneous

  context "Image fields" do
    setup do
      @field = FieldTypes::ImageField.new(:name => "image")
    end
    should "accept and not alter URL values" do
      url =  "http://example.com/image.png"
      @field.value = url
      @field.processed_value.should == url
    end

    should "accept and not alter absolute paths" do
      path = "/images/house.jpg"
      @field.value = path
      @field.processed_value.should == path
    end
  end

  context "image fields" do

    setup do
      tmp = File.join(File.dirname(__FILE__), "../../tmp/media")
      Spontaneous.media_dir = tmp
      @tmp_dir = Pathname.new(tmp)
      @upload_dir = @tmp_dir + "tmp/1234"
      @upload_dir.mkpath

      @revision = 10
      Site.stubs(:working_revision).returns(@revision)

      @src_image =  Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/images/rose.jpg")).realpath
      @origin_image = @upload_dir + "rose.jpg"
      # @origin_image.make_link(@src_image.to_s) unless @origin_image.exist?
      FileUtils.cp(@src_image.to_s, @origin_image.to_s)
      @origin_image = @origin_image.realpath.to_s
      # @digest = OpenSSL::Digest::MD5.new.file(@origin_image).hexdigest
      # p @digest

      class ::ResizingImageField < FieldTypes::ImageField
        sizes :preview => { :width => 200 },
          :tall => { :height => 200 },
          :thumbnail => { :fit => [50, 50] },
          :icon => { :crop => [50, 50] }
      end

      ResizingImageField.register

      class ::ContentWithImage < Content
        field :photo, :resizing_image
      end
      @instance = ContentWithImage.new

      @content_id = 234
      @instance.stubs(:id).returns(@content_id)
      @image = @instance.photo
      @image.owner.should == @instance
      @image.value = @origin_image.to_s
    end

    teardown do
      Object.send(:remove_const, :ContentWithImage)
      Object.send(:remove_const, :ResizingImageField)
      (@tmp_dir + "..").rmtree
    end

    should "have image dimension and filesize information" do
      @image.src.should == "/media/00234/0010/rose.jpg"
      @image.filesize.should == 54746
      @image.width.should == 400
      @image.height.should == 533
    end

    should "have access to the original uploaded file through field.original" do
      @image.src.should == "/media/00234/0010/rose.jpg"
      @image.original.width.should == @image.width
      @image.original.height.should == @image.height
      @image.original.filesize.should == @image.filesize
      @image.filepath.should == File.expand_path(File.join(Spontaneous.media_dir, "00234/0010/rose.jpg"))
    end


    should "have a 'sizes' config option that generates resized versions" do
      assert_same_elements ResizingImageField.size_definitions.keys, [:preview, :thumbnail, :icon, :tall]
    end

    should "serialise attributes" do
      serialised = @image.serialize[:attributes]
      [:preview, :thumbnail, :icon, :tall].each do |size|
        serialised.key?(size).should be_true
        serialised[size][:src].should == "/media/00234/0010/rose.#{size}.jpg"
      end
      serialised[:preview][:width].should == 200
      serialised[:tall][:height].should == 200
      serialised[:thumbnail][:width].should == 38
      serialised[:thumbnail][:height].should == 50
      serialised[:icon][:width].should == 50
      serialised[:icon][:height].should == 50
      # pp serialised
    end

      should "persist attributes" do
        @instance.save
        @instance = ContentWithImage[@instance[:id]]
        @instance.photo.thumbnail.src.should == "/media/00234/0010/rose.thumbnail.jpg"
        @instance.photo.original.src.should == "/media/00234/0010/rose.jpg"
      end
  end
end
