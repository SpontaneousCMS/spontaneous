# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class MediaTest < MiniTest::Spec
  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
  end

  context "Utilitity methods" do
    should "be able to sanitise filenames" do
      filename = "Something with-dodgy 'characters'.many.jpg"
      Media.to_filename(filename).should == "Something-with-dodgy-characters.many.jpg"
    end
  end
  context "Content items" do
    setup do
      # @media_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../tmp/media"))
      # Spontaneous.media_dir = @media_dir
      Site.stubs(:working_revision).returns(74)
      @instance = Content.new
      @instance.stubs(:id).returns(101)
    end

    should "be able to generate a revision and id based media path" do
      @instance.media_filepath("something.jpg").should == File.join(@site.media_dir, "00101/0074/something.jpg")
      @instance.media_urlpath("something.jpg").should == "/media/00101/0074/something.jpg"
    end

    context "file manipulation" do
      setup do
        @tmp_dir = Pathname.new(Spontaneous.media_dir)
        @src_image =  Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/images/rose.jpg")).realpath
        @upload_dir = @tmp_dir + "tmp/1234"
        @upload_dir.mkpath
        @origin_image = @upload_dir + "rose.jpg"
        FileUtils.cp(@src_image.to_s, @origin_image.to_s)
      end

      teardown do
        # (@tmp_dir + "..").rmtree
      end

      should "be able to move a file into the media path" do
        @instance.make_media_file(@origin_image)
        @origin_image.exist?.should be_true
        dest_image = @tmp_dir + "00101/0074/rose.jpg"
        dest_image.exist?.should be_true
      end

      should "honour the filename parameter when creating media files" do
        @instance.make_media_file(@origin_image, 'crysanthemum.jpg')
        @origin_image.exist?.should be_true
        dest_image = @tmp_dir + "00101/0074/crysanthemum.jpg"
        dest_image.exist?.should be_true
      end

      should "sanitise filenames" do
        origin_image = @upload_dir + "illegal filename!.jpg"
        FileUtils.cp(@src_image.to_s, origin_image.to_s)
        @instance.make_media_file(origin_image)
        dest_image = @tmp_dir + "00101/0074/illegal-filename.jpg"
        dest_image.exist?.should be_true
      end
      should "sanitise custom filenames" do
        origin_image = @upload_dir + "rose.jpg"
        FileUtils.cp(@src_image.to_s, origin_image.to_s)
        @instance.make_media_file(origin_image,  "other, 'illegal' filename!.jpg")
        dest_image = @tmp_dir + "00101/0074/other-illegal-filename.jpg"
        dest_image.exist?.should be_true
      end
    end
  end
end
