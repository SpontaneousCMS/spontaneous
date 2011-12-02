# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

class MediaTest < MiniTest::Spec
  def setup
    @site = setup_site
  end

  def teardown
    teardown_site
    S::Content.delete
  end

  context "Utility methods" do
    should "be able to sanitise filenames" do
      filename = "Something with-dodgy 'characters'.many.jpg"
      Media.to_filename(filename).should == "Something-with-dodgy-characters.many.jpg"
    end
  end

  context "Local media files" do
    setup do
      @media_dir = Dir.mktmpdir
      @storage = Spontaneous::Storage::Local.new(@media_dir, '/media')
      @site.stubs(:storage).with(anything).returns(@storage)
      @content = S::Content.create
      @content.stubs(:id).returns(99)
      Spontaneous::State.stubs(:revision).returns(853)
    end

    should "return an absolute path for the url" do
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.url.should == "/media/00099/0853/file-name.txt"
    end

    should "place files into its configured root" do
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.path.should == File.join(@media_dir, "/00099/0853/file-name.txt")
    end

    should "know its mimetype" do
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.mimetype.should == "text/plain"
      file = Spontaneous::Media::File.new(@content, "file name.jpg")
      file.mimetype.should == "image/jpeg"
      file = Spontaneous::Media::File.new(@content, "file name.jpg", "text/html")
      file.mimetype.should == "text/html"
    end

    should "create a new instance with a different name" do
      file1 = Spontaneous::Media::File.new(@content, "file name.txt")
      file2 = file1.rename("another.jpg")
      file2.owner.should == file1.owner
      file2.mimetype.should == file1.mimetype
      file2.url.should == "/media/00099/0853/another.jpg"
    end

    should "be able to copy a file into place if passed the path of an existing file" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(file_path).should be_false
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.copy(existing_file)
      ::File.exist?(file_path).should be_true
    end

    should "be able to copy a file into place if passed the path of an existing file" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(file_path).should be_false
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
      ::File.exist?(file_path).should be_true
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
