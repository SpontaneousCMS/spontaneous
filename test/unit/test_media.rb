# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'fog'

describe "Media" do
  before do
    @site = setup_site
  end

  after do
    ::Content.delete
    teardown_site
  end

  def file(*args)
    @site.file(*args)
  end

  def tempfile(*args)
    @site.tempfile(*args)
  end

  describe "Utility methods" do
    it "be able to sanitise filenames" do
      filename = "Something with-dodgy 'characters'.many.jpg"
      S::Media.to_filename(filename).must_equal "Something-with-dodgy-characters.many.jpg"
    end
  end

  describe "All media files" do
    it "know their mimetype" do
      file = file(@content, "file name.txt")
      file.mimetype.must_equal "text/plain"
      file = file(@content, "file name.jpg")
      file.mimetype.must_equal "image/jpeg"
      file = file(@content, "file name.jpg", "text/html")
      file.mimetype.must_equal "text/html"
    end

  end

  describe "cloud media files" do
    before do
      Fog.mock!
      @bucket_name = "media.example.com"
      @aws_credentials = {
        :provider=>"AWS",
        :aws_secret_access_key=>"SECRET_ACCESS_KEY",
        :aws_access_key_id=>"ACCESS_KEY_ID",
        :public_host => "http://media.example.com"
      }
      @storage = Spontaneous::Media::Store::Cloud.new("S3", @aws_credentials, 'media.example.com')
      @storage.backend.directories.create(:key => @bucket_name)
      @site.storage_backends.unshift(@storage)
      @content = ::Piece.create
      @content.stubs(:id).returns(99)
      Spontaneous::State.stubs(:revision).returns(853)
    end

    it "return an absolute path for the url" do
      file = file(@content, "file name.txt")
      file.url.must_equal "/00099/0853/file-name.txt"
    end

    it "create a new instance with a different name" do
      file1 = file(@content, "file name.txt")
      file2 = file1.rename("another.jpg")
      file2.owner.must_equal file1.owner
      file2.mimetype.must_equal "image/jpeg"
      file2.url.must_equal "/00099/0853/another.jpg"
    end

    it "be able to copy a file into place if passed the path of an existing file" do
      @storage.bucket.files.expects(:create).with{ |args|
        args[:key] == "00099/0853/file-name.txt" &&
          args[:body].is_a?(File) &&
          args[:public] == true
      }
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      assert ::File.exist?(existing_file)
      file = file(@content, "file name.txt")
      file.copy(existing_file)
    end

    it "be able to copy a file into place if passed the file handle of an existing file" do
      @storage.bucket.files.expects(:create).with{ |args|
        args[:key] == "00099/0853/file-name.txt" &&
          args[:body].is_a?(File) &&
          args[:public] == true
      }
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      assert ::File.exist?(existing_file)
      file = file(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
    end

    it "provide an open method that writes files to the correct location" do
      @storage.bucket.files.expects(:create).with() { |args|
        args[:key] == "00099/0853/file-name.txt" &&
          (args[:body].is_a?(File) || args[:body].is_a?(Tempfile)) &&
          args[:public] == true
      }

      file = file(@content, "file name.txt")
      content_string = "Hello"
      file.open do |f|
        f.write(content_string)
      end
    end
  end

  describe "Local media files" do
    before do
      @media_dir = Dir.mktmpdir
      @storage = Spontaneous::Media::Store::Local.new("local", @media_dir, '/media')
      @site.stubs(:storage_for_mimetype).with(anything).returns(@storage)
      @content = ::Piece.create
      @content.stubs(:id).returns(99)
      Spontaneous::State.stubs(:revision).returns(853)
    end

    it "return an absolute path for the url" do
      file = file(@content, "file name.txt")
      file.url.must_equal "/media/00099/0853/file-name.txt"
    end

    it "place files into its configured root" do
      file = file(@content, "file name.txt")
      file.path.must_equal File.join(@media_dir, "/00099/0853/file-name.txt")
    end

    it "create a new instance with a different name" do
      file1 = file(@content, "file name.txt")
      file2 = file1.rename("another.jpg")
      file2.owner.must_equal file1.owner
      file2.mimetype.must_equal "image/jpeg"
      file2.url.must_equal "/media/00099/0853/another.jpg"
    end

    it "be able to copy a file into place if passed the path of an existing file" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      refute ::File.exist?(file_path)
      assert ::File.exist?(existing_file)
      file = file(@content, "file name.txt")
      file.copy(existing_file)
      assert ::File.exist?(file_path)
      file.source.must_equal existing_file
    end

    it "be able to copy a file into place if passed the handle of an existing file" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      refute ::File.exist?(file_path)
      assert ::File.exist?(existing_file)
      file = file(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
      assert ::File.exist?(file_path)
      file.source.must_equal existing_file
    end

    it "provide an open method that writes files to the correct location" do
      file_path = File.join(@media_dir, "/00099/0853/file-name.txt")
      refute ::File.exist?(file_path)
      file = file(@content, "file name.txt")
      content_string = "Hello"
      file.open do |f|
        f.write(content_string)
      end
      File.read(file_path).must_equal content_string
    end
  end

  describe "temporary media items" do
    before do
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
      cloud = Spontaneous::Media::Store::Cloud.new("S3", @aws_credentials, 'media.example.com')
      cloud.backend.directories.create(:key => @bucket_name)
      @site.stubs(:storage_for_mimetype).with(anything).returns(cloud)
      @media_dir = Dir.mktmpdir
      @storage = Spontaneous::Media::Store::Local.new("local", @media_dir, '/media')
      @site.stubs(:local_storage).with(anything).returns(@storage)
      @site.stubs(:default_storage).with(anything).returns(@storage)
      @content = ::Piece.create
      @content.stubs(:id).returns(99)
    end

    it "return an absolute path for the url" do
      file = tempfile(@content, "file name.txt")
      file.url.must_equal "/media/tmp/00099/file-name.txt"
    end

    it "place files into its configured root" do
      file = tempfile(@content, "file name.txt")
      file.path.must_equal File.join(@media_dir, "/tmp/00099/file-name.txt")
    end

    it "be able to copy a file into place if passed the path of an existing file" do
      file_path = File.join(@media_dir, "/tmp/00099/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      refute ::File.exist?(file_path)
      assert ::File.exist?(existing_file)
      file = tempfile(@content, "file name.txt")
      file.copy(existing_file)
      assert ::File.exist?(file_path)
      file.source.must_equal existing_file
    end

    it "be able to copy a file into place if passed the handle of an existing file" do
      file_path = File.join(@media_dir, "/tmp/00099/file-name.txt")
      existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
      refute ::File.exist?(file_path)
      assert ::File.exist?(existing_file)
      file = tempfile(@content, "file name.txt")
      File.open(existing_file, 'rb') do |f|
        file.copy(f)
      end
      assert ::File.exist?(file_path)
      file.source.must_equal existing_file
    end

    it "provide an open method that writes files to the correct location" do
      file_path = File.join(@media_dir, "/tmp/00099/file-name.txt")
      refute ::File.exist?(file_path)
      file = tempfile(@content, "file name.txt")
      content_string = "Hello"
      file.open do |f|
        f.write(content_string)
      end
      File.read(file_path).must_equal content_string
    end
  end
end
