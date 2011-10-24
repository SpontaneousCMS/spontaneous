# encoding: UTF-8


require File.expand_path('../../test_helper', __FILE__)
# require 'openssl'

class ImagesTest < MiniTest::Spec
  include Spontaneous
  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Image fields set using absolute values" do
    setup do
      @image = FieldTypes::ImageField.new(:name => "image")
    end
    should "accept and not alter URL values" do
      url =  "http://example.com/image.png"
      @image.value = url
      @image.processed_value.should == url
      @image.src.should == url
      @image.original.src.should == url
    end

    should "accept and not alter absolute paths" do
      path = "/images/house.jpg"
      @image.value = path
      @image.processed_value.should == path
      @image.src.should == path
      @image.original.src.should == path
    end
  end

  context "Image fields" do
    setup do
      tmp = File.join(@site.root, "tmp/media")
      # Spontaneous.media_dir = tmp
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

      class ::ResizingImageField < FieldTypes::ImageField
        size :preview do
          width 200
        end
        size :tall do
          height 200
        end
        size :thumbnail do
          fit 50, 50
        end
        size :icon do
          crop 50, 50
        end
        size :greyscale do
          fit 50, 50
          greyscale
          gaussian_blur 10
        end
        size :reformatted do
          format 'png'
        end
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
      # silence_logger {
        @image.value = @origin_image.to_s
      # }
    end

    teardown do
      Object.send(:remove_const, :ContentWithImage) rescue nil
      Object.send(:remove_const, :ResizingImageField) rescue nil
      # (@tmp_dir + "..").rmtree
    end

    context "with defined sizes" do
      setup do
      end

      should "create resized versions of the input image" do
        ImageSize.read(@image.preview.filepath).should == [200, 267]
        ImageSize.read(@image.tall.filepath).should == [150, 200]
        ImageSize.read(@image.thumbnail.filepath).should == [38, 50]
        ImageSize.read(@image.icon.filepath).should == [50, 50]
        ImageSize.read(@image.greyscale.filepath).should == [38, 50]
      end

      should "preserve new format if processing has altered it" do
        @image.reformatted.src.should =~ /\.png$/
      end
    end
    context "in templates" do

      should "render an <img/> tag in HTML format" do
        assert_same_elements @image.to_html.split(' '), %(<img src="#{@image.src}" width="400" height="533" alt="" />).split(" ")
      end

      should "use passed hash to overwrite tag attributes" do
        attr = {
          :alt => "Magic",
          :class => "magic",
          :rel => "lightbox",
          :random => "present"
        }
        assert_same_elements @image.to_html(attr).split(" "), %(<img src="#{@image.src}" width="400" height="533" alt="Magic" class="magic" rel="lightbox" random="present" />).split(" ")
      end

      should "be intelligent about setting width & height" do
        assert_same_elements @image.to_html({ :width => 100 }).split(" "), %(<img src="#{@image.src}" width="100" alt="" />).split(" ")
        assert_same_elements @image.to_html({ :height => 100 }).split(" "), %(<img src="#{@image.src}" height="100" alt="" />).split(" ")
        assert_same_elements @image.to_html({ :width => 100, :height => 100 }).split(" "), %(<img src="#{@image.src}" width="100" height="100" alt="" />).split(" ")
      end

      should "turn off setting with & height if either is passed as false" do
        assert_same_elements @image.to_html({ :width => false }).split(" "), %(<img src="#{@image.src}" alt="" />).split(" ")
      end

      should "escape values in params" do
        assert_same_elements @image.to_html({ :alt => "<danger\">" }).split(" "), %(<img src="#{@image.src}" width="400" height="533" alt="&lt;danger&quot;&gt;" />).split(" ")
      end

      should "not include size parameters unless known" do
        @image.value = "/somethingunknown.gif"
        @image.src.should ==  "/somethingunknown.gif"
        assert_same_elements @image.to_html.split(" "), %(<img src="#{@image.src}" alt="" />).split(" ")
      end

      should "output image tags for its sizes too" do
        assert_same_elements @image.thumbnail.to_html(:alt => "Thumb").split(' '), %(<img src="#{@image.thumbnail.src}" width="38" height="50" alt="Thumb" />).split(" ")
      end
    end
    context "defined by classes" do
      setup do
      end

      teardown do
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
        assert_same_elements ResizingImageField.size_definitions.keys, [:preview, :thumbnail, :icon, :tall, :greyscale, :reformatted]
      end

      should "serialise attributes" do
        serialised = S::FieldTypes.deserialize_field(@image.serialize_db)[:processed_values]
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
      end

      should "persist attributes" do
        @instance.save
        @instance = ContentWithImage[@instance[:id]]
        @instance.photo.thumbnail.src.should == "/media/00234/0010/rose.thumbnail.jpg"
        @instance.photo.original.src.should == "/media/00234/0010/rose.jpg"
      end

      should "not throw errors when accessing size before value has been assigned" do
        instance = ContentWithImage.new
        instance.photo.thumbnail.should_not be_nil
        instance.photo.thumbnail.src.should == ""
      end
    end

    context "defined anonymously" do
      setup do
        # class ::ContentWithImage < Content
        #   field :photo, :image do
        #     sizes :preview => { :width => 200 },
        #       :tall => { :height => 200 },
        #       :thumbnail => { :fit => [50, 50] },
        #       :icon => { :crop => [50, 50] }
        #   end
        # end
        # @instance = ContentWithImage.new

        # @content_id = 234
        # @instance.stubs(:id).returns(@content_id)
        # @image = @instance.photo
        # @image.owner.should == @instance
        # @image.value = @origin_image.to_s
      end

      teardown do
        # Object.send(:remove_const, :ContentWithImage)
        # (@tmp_dir + "..").rmtree
      end

      should "have image dimension and filesize information" do
        @image.src.should == "/media/00234/0010/rose.jpg"
        @image.filesize.should == 54746
        @image.width.should == 400
        @image.height.should == 533
      end

      should "have access to the original uploaded file through field.original" do
        @image.original.width.should == @image.width
        @image.original.height.should == @image.height
        @image.original.filesize.should == @image.filesize
      end
      should "have a 'sizes' config option that generates resized versions" do
        assert_same_elements @image.class.size_definitions.keys, [:preview, :thumbnail, :icon, :tall, :greyscale, :reformatted]
        assert_same_elements @image.class.sizes.keys, [:preview, :thumbnail, :icon, :tall, :greyscale, :reformatted]
      end

      should "serialise attributes" do
        serialised = S::FieldTypes.deserialize_field(@image.serialize_db)[:processed_values]
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
end
