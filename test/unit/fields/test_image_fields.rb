# encoding: UTF-8


require File.expand_path('../../../test_helper', __FILE__)
require 'fog'

describe "Image Fields" do

  before do
    @site = setup_site
  end

  after do
    teardown_site
  end

  describe "Image fields set using absolute values" do
    before do
      class ::Piece < ::Content::Piece
      end
      @owner = Piece.create
      @image = S::Field::Image.new(:name => "image")
      @image.owner = @owner
      @image.prototype = Spontaneous::Prototypes::FieldPrototype.new(@site.model, :image, :image)
    end

    it "accept and not alter URL values" do
      url =  "http://example.com/image.png"
      @image.value = url
      @image.processed_value.must_equal url
      @image.src.must_equal url
      @image.original.src.must_equal url
    end

    it "accept and not alter absolute paths" do
      path = "/images/house.jpg"
      @image.value = path
      @image.processed_value.must_equal path
      @image.src.must_equal path
      @image.original.src.must_equal path
    end
  end

  describe "uploaded files" do
    before do
      # I'm both testing for this and avoiding it happening
      # (optimization can be slow...)
      optim = Spontaneous::Media::Image::Optimizer
      optim.expects(:run).at_least_once

      tmp = File.join(@site.root, "tmp/media")
      # Spontaneous.media_dir = tmp
      @tmp_dir = Pathname.new(tmp)
      @upload_dir = @tmp_dir + "tmp/1234"
      @upload_dir.mkpath

      @revision = 10
      @site.stubs(:working_revision).returns(@revision)

      @src_image =  Pathname.new(File.join(File.dirname(__FILE__), "../../fixtures/images/rose.jpg")).realpath
      @origin_image = @upload_dir + "rose.jpg"
      FileUtils.cp(@src_image.to_s, @origin_image.to_s)
      @origin_image = @origin_image.realpath.to_s

      class ::ResizingImageField < S::Field::Image
        size :preview, :optimize => false do
          width 200
        end
        size :tall do
          height 200
        end
        size :thumbnail do
          fit width: 50, height: 50
        end
        size :icon do
          fill width: 50, height: 50
        end
        size :reformatted, :format => :png
      end

      ResizingImageField.register

      class ::ContentWithImage < ::Content::Piece
        field :photo, :resizing_image
      end

      @instance = ContentWithImage.new

      @content_id = 234
      @instance.stubs(:id).returns(@content_id)
      @image = @instance.photo
    end

    after do
      Object.send(:remove_const, :ContentWithImage) rescue nil
      Object.send(:remove_const, :ResizingImageField) rescue nil
    end

    describe "local storage" do
      before do

        @image.owner.must_equal @instance
        @image.value = @origin_image.to_s

        @instance.save
      end


      describe "with defined sizes" do
        before do
        end

        it "create resized versions of the input image" do
          S::Media::Image.dimensions(@image.preview.filepath).must_equal [200, 267]
          S::Media::Image.dimensions(@image.tall.filepath).must_equal [150, 200]
          S::Media::Image.dimensions(@image.thumbnail.filepath).must_equal [38, 50]
          S::Media::Image.dimensions(@image.icon.filepath).must_equal [50, 50]
        end

        it "preserve new format if processing has altered it" do
          @image.reformatted.src.must_match /\.png$/
        end
      end

      describe "optimization" do
        it "should be enabled by default" do
          @image.value = @origin_image.to_s
        end
      end

      describe "in templates" do

        after do
          Spontaneous::Field::Image.default_attributes = {}
        end

        it "render an <img/> tag in HTML format" do
          assert_has_elements @image.to_html.split(' '), %(<img src="#{@image.src}" alt="" />).split(" ")
        end

        it 'will fill in the image’s size if told to do so' do
          expected = %(<img src="#{@image.src}" width="400" height="533" alt="" />).split(" ")
          assert_has_elements @image.to_html(size: true).split(' '), expected
          assert_has_elements @image.to_html(size: :auto).split(' '), expected
          assert_has_elements @image.to_html(size: 'auto').split(' '), expected
        end

        it 'will fill in the image’s width with natural value if given a size of auto' do
          expected = %(<img src="#{@image.src}" width="400" alt="" />).split(" ")
          assert_has_elements @image.to_html(width: :auto).split(' '), expected
          assert_has_elements @image.to_html(width: true).split(' '), expected
          assert_has_elements @image.to_html(width: 'auto').split(' '), expected
        end

        it 'will fill in the image’s height with natural value if given a size of auto' do
          expected = %(<img src="#{@image.src}" height="533" alt="" />).split(" ")
          assert_has_elements @image.to_html(height: true).split(' '), expected
          assert_has_elements @image.to_html(height: :auto).split(' '), expected
          assert_has_elements @image.to_html(height: 'auto').split(' '), expected
        end

        it "use passed hash to overwrite tag attributes" do
          attr = {
            :alt => "Magic",
            :class => "magic",
            :rel => "lightbox",
            :random => "present"
          }
          assert_has_elements @image.to_html(attr).split(" "), %(<img src="#{@image.src}" alt="Magic" class="magic" rel="lightbox" random="present" />).split(" ")
        end

        it "be intelligent about setting width & height" do
          @image.to_html({ width: 100 }).split(" ").must_have_elements %(<img src="#{@image.src}" width="100" alt="" />).split(" ")
          assert_has_elements @image.to_html({ height: 100 }).split(" "), %(<img src="#{@image.src}" height="100" alt="" />).split(" ")
          assert_has_elements @image.to_html({ width: 100, height: 100 }).split(" "), %(<img src="#{@image.src}" width="100" height="100" alt="" />).split(" ")
        end

        it "turn off setting width & height if either is passed as false" do
          assert_has_elements @image.to_html({ :width => false }).split(" "), %(<img src="#{@image.src}" alt="" />).split(" ")
        end

        it "escape values in params" do
          assert_has_elements @image.to_html({ :alt => "<danger\">" }).split(" "), %(<img src="#{@image.src}" alt="&lt;danger&quot;&gt;" />).split(" ")
        end

        it "not include size parameters unless known" do
          @image.value = "/somethingunknown.gif"
          @image.src.must_equal  "/somethingunknown.gif"
          assert_has_elements @image.to_html.split(" "), %(<img src="#{@image.src}" alt="" />).split(" ")
        end

        it "output image tags for its sizes too" do
          assert_has_elements @image.thumbnail.to_html(alt: "Thumb", size: true).split(' '), %(<img src="#{@image.thumbnail.src}" width="38" height="50" alt="Thumb" />).split(" ")
        end

        it 'allows for setting site-wide options' do
          Spontaneous::Field::Image.default_attributes = { width: :auto, alt: 'Banana'}
          assert_has_elements @image.to_html().split(' '), %(<img src="#{@image.src}" width="400" alt="Banana" />).split(" ")
          assert_has_elements @image.to_html(width: false, alt: 'Other').split(' '), %(<img src="#{@image.src}" alt="Other" />).split(" ")
        end

        it 'allows for setting values with a proc' do
          Spontaneous::Field::Image.default_attributes = { something: proc { |field| field.name }}
          assert_has_elements @image.to_html().split(' '), %(<img src="#{@image.src}" alt="" something="photo" />).split(" ")
        end

        it 'allows for setting data-* values with a hash' do
          assert_has_elements @image.to_html(data: {name: proc { |field| field.name }, id: proc { |field| field.owner.id }}).split(' '), %(<img src="#{@image.src}" alt="" data-name="photo" data-id="#{@content_id}" />).split(" ")
        end
      end
      describe "defined by classes" do
        before do
        end

        after do
        end

        it "have image dimension and filesize information" do
          @image.src.must_equal "/media/00234/0010/rose.jpg"
          @image.width.must_equal 400
          @image.height.must_equal 533
        end

        it "have access to the original uploaded file through field.original yyy" do
          @image.src.must_equal "/media/00234/0010/rose.jpg"
          @image.original.width.must_equal @image.width
          @image.original.height.must_equal @image.height
          md5 = Digest::MD5.file(@src_image).hexdigest
          @image.filepath.must_equal ["rose.jpg", md5].to_json
        end


        it "have a 'sizes' config option that generates resized versions" do
          assert_has_elements ResizingImageField.size_definitions.keys, [:original, :__ui__, :preview, :thumbnail, :icon, :tall, :reformatted]
        end

        it "serialise attributes" do
          serialised = S::Field.deserialize_field(@image.serialize_db)[:processed_values]
          [:preview, :thumbnail, :icon, :tall].each do |size|
            assert serialised.key?(size)
            serialised[size][:src].must_equal "/media/00234/0010/rose.#{size}.jpg"
          end
          serialised[:preview][:width].must_equal 200
          serialised[:tall][:height].must_equal 200
          serialised[:thumbnail][:width].must_equal 38
          serialised[:thumbnail][:height].must_equal 50
          serialised[:icon][:width].must_equal 50
          serialised[:icon][:height].must_equal 50
        end

        it "persist attributes" do
          @instance.save
          @instance = ContentWithImage[@instance[:id]]
          @instance.photo.thumbnail.src.must_equal "/media/00234/0010/rose.thumbnail.jpg"
          @instance.photo.original.src.must_equal "/media/00234/0010/rose.jpg"
        end

        it "not throw errors when accessing size before value has been assigned" do
          instance = ContentWithImage.new
          instance.photo.thumbnail.wont_be_nil
          instance.photo.thumbnail.src.must_equal ""
        end
      end

      describe "defined anonymously" do
        it "have image dimension and filesize information" do
          @image.src.must_equal "/media/00234/0010/rose.jpg"
          @image.width.must_equal 400
          @image.height.must_equal 533
        end

        it "have access to the original uploaded file through field.original" do
          @image.original.width.must_equal @image.width
          @image.original.height.must_equal @image.height
        end
        it "have a 'sizes' config option that generates resized versions" do
          assert_has_elements @image.class.size_definitions.keys, [:original, :__ui__, :preview, :thumbnail, :icon, :tall, :reformatted]
          assert_has_elements @image.class.sizes.keys, [:original, :__ui__, :preview, :thumbnail, :icon, :tall, :reformatted]
        end

        it "serialise attributes" do
          serialised = S::Field.deserialize_field(@image.serialize_db)[:processed_values]
          [:preview, :thumbnail, :icon, :tall].each do |size|
            assert serialised.key?(size)
            serialised[size][:src].must_equal "/media/00234/0010/rose.#{size}.jpg"
          end
          serialised[:preview][:width].must_equal 200
          serialised[:tall][:height].must_equal 200
          serialised[:thumbnail][:width].must_equal 38
          serialised[:thumbnail][:height].must_equal 50
          serialised[:icon][:width].must_equal 50
          serialised[:icon][:height].must_equal 50
        end

        it "persist attributes" do
          @instance.save
          @instance = ContentWithImage[@instance[:id]]
          @instance.photo.thumbnail.src.must_equal "/media/00234/0010/rose.thumbnail.jpg"
          @instance.photo.original.src.must_equal "/media/00234/0010/rose.jpg"
        end
      end

    end

    describe "cloud storage" do
      before do
        @bucket_name = "media.example.com"
        @aws_credentials = {
          :provider=>"AWS",
          :aws_secret_access_key=>"SECRET_ACCESS_KEY",
          :aws_access_key_id=>"ACCESS_KEY_ID",
          :public_host => "http://media.example.com"
        }
        ::Fog.mock!
        @storage = Spontaneous::Media::Store::Cloud.new("S3", @aws_credentials, 'media.example.com')
        @storage.backend.directories.create(:key => @bucket_name)
        @site.storage_backends.unshift(@storage)
        @image.value = @origin_image.to_s
      end

      after do
        ::Fog::Mock.reset
      end

      it "have full urls for all the src attributes" do
        @image.original.src.must_equal "http://media.example.com/00234/0010/rose.jpg"
        @image.thumbnail.src.must_equal "http://media.example.com/00234/0010/rose.thumbnail.jpg"
      end

      it "allows for reconfiguring the media urls" do
        @storage.url_mapper = proc { |path| "http://cdn.example.com#{path}" }
        @image.original.src.must_equal "http://cdn.example.com/00234/0010/rose.jpg"
        @image.thumbnail.src.must_equal "http://cdn.example.com/00234/0010/rose.thumbnail.jpg"
      end
    end
  end

  describe '#blank?' do
    before do
      class ::ContentWithImage < ::Content::Piece
        field :photo, :image do
          size :smaller do
            fit width: 100, height: 100
          end
        end
      end

      @instance = ContentWithImage.new

      # @content_id = 234
      # @instance.stubs(:id).returns(@content_id)
      @field = @instance.photo
    end

    after do
      Object.send(:remove_const, :ContentWithImage) rescue nil
    end

    it 'returns true for empty images' do
      @field.blank?.must_equal true
      @field.original.blank?.must_equal true
      @field.smaller.blank?.must_equal true
    end

    it 'returns false for images with values' do
      path = File.expand_path("../../../../fixtures/images/rose.jpg", __FILE__)
      @field.value = path
      @instance.save
      @field.blank?.must_equal false
      @field.original.blank?.must_equal false
      @field.smaller.blank?.must_equal false
    end

    describe 'with cloud storage' do
      before do
        @bucket_name = "media.example.com"
        @aws_credentials = {
          :provider=>"AWS",
          :aws_secret_access_key=>"SECRET_ACCESS_KEY",
          :aws_access_key_id=>"ACCESS_KEY_ID",
          :public_host => "http://media.example.com"
        }
        ::Fog.mock!
        @storage = Spontaneous::Media::Store::Cloud.new("S3", @aws_credentials, 'media.example.com')
        @storage.backend.directories.create(:key => @bucket_name)
        @site.storage_backends.unshift(@storage)
      end

      it 'returns true for empty images' do
        @field.blank?.must_equal true
        @field.original.blank?.must_equal true
        @field.smaller.blank?.must_equal true
      end
      it 'returns false for images with values' do
        path = File.expand_path("../../../../fixtures/images/rose.jpg", __FILE__)
        @field.value = path
        @instance.save
        @field.blank?.must_equal false
        @field.original.blank?.must_equal false
        @field.smaller.blank?.must_equal false
      end
    end
  end

  describe "clearing" do
    def assert_image_field_empty
      @field.value.must_equal ''
      @field.src.must_equal ''
      @field.filesize.must_equal 0
      @field.smaller.value.must_equal ''
    end

    before do
      class ::ContentWithImage < ::Content::Piece
        field :photo, :image do
          size :smaller do
            fit width: 100, height: 100
          end
        end
      end

      @instance = ContentWithImage.new

      @content_id = 234
      @instance.stubs(:id).returns(@content_id)
      @field = @instance.photo
      path = File.expand_path("../../../../fixtures/images/rose.jpg", __FILE__)
      @field.value = path
    end

    after do
      Object.send(:remove_const, :ContentWithImage) rescue nil
    end

    it "clears the value if set to the empty string" do
      @field.value = ''
      assert_image_field_empty
    end
  end

end
