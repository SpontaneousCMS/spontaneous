# encoding: UTF-8

require File.expand_path('../../../test_helper', __FILE__)
require 'fog'

describe "File Fields" do
  let(:path) { File.expand_path("../../../fixtures/images/vimlogo.pdf", __FILE__) }

  def site
    @site = setup_site
    @now = Time.now
    stub_time(@now)
    Spontaneous::State.delete
    @site.background_mode = :immediate
  end
  before do
    site
    assert File.exists?(path), "Test file #{path} does not exist"
    @content_class = Class.new(::Piece)
    @prototype = @content_class.field :file
    @content_class.stubs(:name).returns("ContentClass")
    @instance = @content_class.create
    @field = @instance.file
  end

  after do
    teardown_site
  end
  it "have a distinct editor class" do
    @prototype.instance_class.editor_class.must_equal "Spontaneous.Field.File"
  end

  it "adopt any field called 'file'" do
    assert @field.is_a?(Spontaneous::Field::File), "Field should be an instance of FileField but instead has the following ancestors #{ @prototype.instance_class.ancestors }"
  end

  it "gives the right value for #blank?" do
    @field.blank?.must_equal true
    @field.value = 'http://example.com/image.jpg'
    @field.blank?.must_equal false
  end

  it "copy files to the media folder" do
    File.open(path, 'rb') do |file|
      @field.value = {
        :tempfile => file,
        :type => "application/pdf",
        :filename => "vimlogo.pdf"
      }
    end
    url = @field.value
    path = File.join File.dirname(Spontaneous.media_dir), url
    assert File.exist?(path), "Media file should have been copied into place"
  end

  it "generate the requisite file metadata" do
    File.open(path, 'rb') do |file|
      @field.value = {
        :tempfile => file,
        :type => "application/pdf",
        :filename => "vimlogo.pdf"
      }
    end
    @field.value(:html).must_match %r{/media/.+/vimlogo.pdf$}
    @field.value.must_match %r{/media/.+/vimlogo.pdf$}
    @field.path.must_equal @field.value
    @field.value(:filesize).must_equal 2254
    @field.filesize.must_equal 2254
    @field.value(:filename).must_equal "vimlogo.pdf"
    @field.filename.must_equal "vimlogo.pdf"
  end

  it "just accept the given value if passed a path to a non-existant file" do
    @field.value = "/images/nosuchfile.rtf"
    @field.value.must_equal  "/images/nosuchfile.rtf"
    @field.filename.must_equal "nosuchfile.rtf"
    @field.filesize.must_equal 0
  end

  it "copy the given file if passed a path to an existing file" do
    @field.value = path
    @field.value.must_match %r{/media/.+/vimlogo.pdf$}
    @field.filename.must_equal "vimlogo.pdf"
    @field.filesize.must_equal 2254
  end

  it "sets the unprocessed value to a JSON encoded array of MD5 hash & filename" do
    @field.value = path
    @instance.save
    @field.unprocessed_value.must_equal ["vimlogo.pdf", "1de7e866d69c2f56b4a3f59ed1c98b74"].to_json
  end

  it "sets the field hash to the MD5 hash of the file" do
    @field.value = path
    @field.file_hash.must_equal "1de7e866d69c2f56b4a3f59ed1c98b74"
  end

  it "sets the original filename of the file" do
    @field.value = path
    @field.original_filename.must_equal "vimlogo.pdf"
  end

  it "doesn't set the hash of a file that can't be found" do
    @field.value = "/images/nosuchfile.rtf"
    @field.file_hash.must_equal ""
  end

  it "sets the original filename of a file that can't be found" do
    @field.value = "/images/nosuchfile.rtf"
    @field.original_filename.must_equal "/images/nosuchfile.rtf"
  end

  it "sets the storage name if given an uploaded file" do
    @field.value = path
    @field.storage_name.must_equal "default"
  end

  it "sets the storage name if given an uploaded file" do
    @field.value = path
    @field.storage.must_equal @site.storage
  end

  it "sets the storage name to nil for file paths" do
    @field.value = "/images/nosuchfile.rtf"
    @field.storage_name.must_equal nil
  end

  it "allows for re-configuring the generated media URLs" do
    @field.value = path
    @field.path.must_match %r{^/media/.+/vimlogo.pdf$}
    storage = @site.storage("default")
    storage.url_mapper = ->(path) { "http://media.example.com#{path}"}
    @field.value(:html).must_match %r{^http://media.example.com/media/.+/vimlogo.pdf$}
    @field.path.must_match %r{^http://media.example.com/media/.+/vimlogo.pdf$}
    @field.url.must_match %r{^http://media.example.com/media/.+/vimlogo.pdf$}
  end

  describe "clearing" do
    def assert_file_field_empty
      @field.value.must_equal ''
      @field.filename.must_equal ''
      @field.filesize.must_equal 0
    end

    before do
      path = File.expand_path("../../fixtures/images/vimlogo.pdf", __FILE__)
      @field.value = path
    end

    it "clears the value if set to the empty string" do
      @field.value = ''
      assert_file_field_empty
    end
  end

  describe "with cloud storage" do
    before do
      ::Fog.mock!
      @storage_config = {
        provider: "AWS",
        aws_secret_access_key: "SECRET_ACCESS_KEY",
        aws_access_key_id: "ACCESS_KEY_ID",
        public_host: 'https://media.example.com'
      }
      @storage = S::Media::Store::Cloud.new("S3", @storage_config, "media.example.com")
      @storage.name.must_equal "S3"
      @site.storage_backends.unshift(@storage)
    end

    it "sets the content-disposition header if defined as an 'attachment'" do
      prototype = @content_class.field :attachment, :file, attachment: true
      field = @instance.attachment
      path = File.expand_path("../../../fixtures/images/vimlogo.pdf", __FILE__)
      @storage.expects(:copy).with(path, is_a(Array), { content_type: "application/pdf", content_disposition: 'attachment; filename=vimlogo.pdf'})
      field.value = path
    end

    describe 'storage' do
      before do
        @prototype = @content_class.field :attachment, :file
        @field = @instance.attachment
        @storage.stubs(:copy).with(path, is_a(Array), { content_type: "application/pdf"})
      end

      it "sets the storage name if given an uploaded file" do
        @field.value = path
        @field.storage_name.must_equal "S3"
      end

      it "allows for the file url to be configured by the storage" do
        @field.value = path
        @field.url.must_match %r[^https://media.example.com/0000#{@instance.id}/0001/vimlogo.pdf$]
        @storage.url_mapper = ->(path) { "https://cdn.example.com#{path}" }
        @field.url.must_match %r[^https://cdn.example.com/0000#{@instance.id}/0001/vimlogo.pdf$]
      end

      it 'falls back to the site’s default if initialized before storage_name output was defined' do
        @field.value = path
        @field.stubs(:storage_name).returns('[]')
        @field.url.must_match %r[^/0000#{@instance.id}/0001/vimlogo.pdf$]
      end

      it "gives the right value for #blank?" do
        @field.blank?.must_equal true
        @field.value = path
        @field.blank?.must_equal false
      end
    end
  end
end
