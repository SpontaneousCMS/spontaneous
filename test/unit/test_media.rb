# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'fog'

class MediaTest < MiniTest::Spec
  def setup
    @site = setup_site
  end

  def teardown
    ::Content.delete
    teardown_site
  end

  context "Utility methods" do
    should "be able to sanitise filenames" do
      filename = "Something with-dodgy 'characters'.many.jpg"
      S::Media.to_filename(filename).should == "Something-with-dodgy-characters.many.jpg"
    end
  end

  context "All media files" do
    should "know their mimetype" do
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.mimetype.should == "text/plain"
      file = Spontaneous::Media::File.new(@content, "file name.jpg")
      file.mimetype.should == "image/jpeg"
      file = Spontaneous::Media::File.new(@content, "file name.jpg", "text/html")
      file.mimetype.should == "text/html"
    end

  end

  context "cloud media files" do
    setup do
      Fog.mock!
      @bucket_name = "media.example.com"
      @aws_credentials = {
        :provider=>"AWS",
        :aws_secret_access_key=>"SECRET_ACCESS_KEY",
        :aws_access_key_id=>"ACCESS_KEY_ID",
        :public_host => "http://media.example.com"
      }
      @storage = Spontaneous::Storage::Cloud.new(@aws_credentials, 'media.example.com')
      @storage.backend.directories.create(:key => @bucket_name)
      @site.stubs(:storage).with(anything).returns(@storage)
      @content = ::Piece.create
      @content.stubs(:id).returns(99)
      Spontaneous::State.stubs(:revision).returns(853)
    end
    should "return an absolute path for the url" do
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.url.should == "http://media.example.com/00099-0853-file-name.txt"
    end

    should "create a new instance with a different name" do
      file1 = Spontaneous::Media::File.new(@content, "file name.txt")
      file2 = file1.rename("another.jpg")
      file2.owner.should == file1.owner
      file2.mimetype.should == "image/jpeg"
      file2.url.should == "http://media.example.com/00099-0853-another.jpg"
    end

    should "be able to copy a file into place if passed the path of an existing file" do
      @storage.bucket.files.expects(:create).with{ |args|
        args[:key] == "00099-0853-file-name.txt" &&
          args[:body].is_a?(File) &&
          args[:public] == true
      }
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      file.copy(existing_file)
    end

    should "be able to copy a file into place if passed the file handle of an existing file" do
      @storage.bucket.files.expects(:create).with{ |args|
        args[:key] == "00099-0853-file-name.txt" &&
          args[:body].is_a?(File) &&
          args[:public] == true
      }
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
    end

    should "provide an open method that writes files to the correct location" do
      @storage.bucket.files.expects(:create).with() { |args|
        args[:key] == "00099-0853-file-name.txt" &&
          (args[:body].is_a?(File) || args[:body].is_a?(Tempfile)) &&
          args[:public] == true
      }

      file = Spontaneous::Media::File.new(@content, "file name.txt")
      content_string = "Hello"
      file.open do |f|
        f.write(content_string)
      end
    end
  end

  context "Local media files" do
    setup do
      @media_dir = Dir.mktmpdir
      @storage = Spontaneous::Storage::Local.new(@media_dir, '/media')
      @site.stubs(:storage).with(anything).returns(@storage)
      @content = ::Piece.create
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

    should "create a new instance with a different name" do
      file1 = Spontaneous::Media::File.new(@content, "file name.txt")
      file2 = file1.rename("another.jpg")
      file2.owner.should == file1.owner
      file2.mimetype.should == "image/jpeg"
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
      file.source.should == existing_file
    end

    should "be able to copy a file into place if passed the handle of an existing file" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(file_path).should be_false
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
      ::File.exist?(file_path).should be_true
      file.source.should == existing_file
    end

    should "provide an open method that writes files to the correct location" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      ::File.exist?(file_path).should be_false
      file = Spontaneous::Media::File.new(@content, "file name.txt")
      content_string = "Hello"
      file.open do |f|
        f.write(content_string)
      end
      File.read(file_path).should == content_string
    end
  end

  context "temporary media items" do
    setup do
      # Setup cloud storage as default to ensure that the temp files
      # are bypassing this and being written locally
      Fog.mock!
      @bucket_name = "media.example.com"
      @aws_credentials = {
        :provider=>"AWS",
        :aws_secret_access_key=>"SECRET_ACCESS_KEY",
        :aws_access_key_id=>"ACCESS_KEY_ID",
        :public_host => "http://media.example.com"
      }
      cloud = Spontaneous::Storage::Cloud.new(@aws_credentials, 'media.example.com')
      cloud.backend.directories.create(:key => @bucket_name)
      @site.stubs(:storage).with(anything).returns(cloud)
      @media_dir = Dir.mktmpdir
      @storage = Spontaneous::Storage::Local.new(@media_dir, '/media')
      @site.stubs(:local_storage).with(anything).returns(@storage)
      @site.stubs(:default_storage).with(anything).returns(@storage)
      @content = ::Piece.create
      @content.stubs(:id).returns(99)
    end

    should "return an absolute path for the url" do
      file = Spontaneous::Media::TempFile.new(@content, "file name.txt")
      file.url.should == "/media/tmp/00099/file-name.txt"
    end

    should "place files into its configured root" do
      file = Spontaneous::Media::TempFile.new(@content, "file name.txt")
      file.path.should == File.join(@media_dir, "/tmp/00099/file-name.txt")
    end

    should "be able to copy a file into place if passed the path of an existing file" do
      file_path = File.join(@media_dir, "/tmp/00099/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(file_path).should be_false
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::TempFile.new(@content, "file name.txt")
      file.copy(existing_file)
      ::File.exist?(file_path).should be_true
      file.source.should == existing_file
    end

    should "be able to copy a file into place if passed the handle of an existing file" do
      file_path = File.join(@media_dir, "/tmp/00099/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      ::File.exist?(file_path).should be_false
      ::File.exist?(existing_file).should be_true
      file = Spontaneous::Media::TempFile.new(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
      ::File.exist?(file_path).should be_true
      file.source.should == existing_file
    end

    should "provide an open method that writes files to the correct location" do
      file_path = File.join(@media_dir, "/tmp/00099/file-name.txt")
      ::File.exist?(file_path).should be_false
      file = Spontaneous::Media::TempFile.new(@content, "file name.txt")
      content_string = "Hello"
      file.open do |f|
        f.write(content_string)
      end
      File.read(file_path).should == content_string
    end
  end

  context "Content items" do
    setup do
      # @media_dir = File.expand_path(File.join(File.dirname(__FILE__), "../../tmp/media"))
      # Spontaneous.media_dir = @media_dir
      S::Site.stubs(:working_revision).returns(74)
      @instance = ::Piece.new
      @instance.stubs(:id).returns(101)
    end

    should "be able to generate a revision and id based media path" do
      @instance.media_filepath("something.jpg").should == File.join(@site.media_dir, "00101/0074/something.jpg")
      @instance.media_urlpath("something.jpg").should == "/media/00101/0074/something.jpg"
    end
  end
end
