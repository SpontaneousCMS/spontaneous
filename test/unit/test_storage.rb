# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'fog'

describe "Media Store" do
  before do
    @site = setup_site
    @config_dir = File.expand_path("../../fixtures/storage", __FILE__)
  end

  after do
    teardown_site
  end

  describe "local" do
    before do
      @site.paths.add :config, File.expand_path(@config_dir / "default", __FILE__)
      @site.load_config!
      # sanity check
      assert @site.config.test_setting
      @storage = @site.storage
    end
    it "be the default" do
      @storage.must_be_instance_of Spontaneous::Media::Store::Local
    end
    it "have the right base url" do
      @storage.public_url("test.jpg").must_equal "/media/test.jpg"
    end
    it "test for locality" do
      assert @storage.local?
    end

    it "provide a list of local storage backends" do
      @site.local_storage.must_equal [@storage]
    end

    it "allows for configuring a custom url mapper" do
      require 'zlib'
      mapper = Class.new do
        def initialize(pattern, servers)
          @pattern = pattern
          @servers = servers
          @n = 0
        end

        def server(path)
          @servers[Zlib.crc32(path) % @servers.length]
        end

        def call(path)
          @pattern % [server(path), path]
        end
      end
      @storage.url_mapper = mapper.new("http://%s.cdn.example.com%s", %w(m1 m2 m3 m4))
      @storage.to_url('/image.jpg').must_equal "http://m3.cdn.example.com/image.jpg"
      @storage.to_url('/image.jpg').must_equal "http://m3.cdn.example.com/image.jpg"
      @storage.to_url('/image2.jpg').must_equal "http://m4.cdn.example.com/image2.jpg"
      @storage.to_url('/image2.jpg').must_equal "http://m4.cdn.example.com/image2.jpg"
    end
  end

  describe "cloud" do
    before do
      @bucket_name = "media.example.com"
      @aws_credentials = {
        :provider=>"AWS",
        :aws_secret_access_key=>"SECRET_ACCESS_KEY",
        :aws_access_key_id=>"ACCESS_KEY_ID"
      }
      ::Fog.mock!
      @connection = Fog::Storage.new(@aws_credentials)
      @bucket = @connection.directories.create(key: @bucket_name)
      @site.paths.add :config, File.expand_path(@config_dir / "cloud", __FILE__)
      @site.load_config!
      # sanity check
      assert @site.config.test_setting
      @storage = @site.storage
      # Fog's mocks used to apply directory additions globally but latest version
      # doesn't so I have to stub it out :(
      @storage.stubs(:backend).returns(@connection)
    end

    it "be detected by configuration" do
      @storage.must_be_instance_of Spontaneous::Media::Store::Cloud
    end

    it "have the correct bucket name" do
      @storage.bucket_name.must_equal "media.example.com"
    end

    it "not test as local" do
      refute @storage.local?
    end

    describe "remote files" do
      before do
        @existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
        @media_path = %w(0003 0567 rose.jpg)
      end

      it "have the correct mimetype" do
        file = @storage.copy(@existing_file, @media_path, { content_type: "image/jpeg" })
        file.content_type.must_equal "image/jpeg"
      end

      it "is given a far future cache value" do
        now = DateTime.now
        DateTime.stubs(:now).returns(now)
        file = @storage.copy(@existing_file, @media_path, { content_type: "image/jpeg" })
        file.cache_control.must_equal "max-age=31557600, public"
      end

      it "be set as publicly visible" do
        file = @storage.copy(@existing_file, @media_path, { content_type: "image/jpeg" })
        acl = file.service.get_object_acl(file.directory.key, file.key).body['AccessControlList']
        perms = acl.detect {|grant| grant['Grantee']['URI'] == 'http://acs.amazonaws.com/groups/global/AllUsers' }
        perms["Permission"].must_equal "READ"
      end

      it "sets any additional headers passed to the copy method" do
        file = @storage.copy(@existing_file, @media_path, { content_type: "image/jpeg", content_disposition: "attachment; filename='something.jpg'" })
        file.content_disposition.must_equal "attachment; filename='something.jpg'"
      end
    end

    describe "public urls" do
      before do
        existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
        @media_path = %w(0003 0567 rose.jpg)
        @path = "/" << @media_path.join("/")
        @storage.copy(existing_file, @media_path, { content_type: "image/jpeg" })
      end

      it "have the correct base url" do
        @storage.to_url(@path).must_equal "https://media.example.com.s3.amazonaws.com/0003/0567/rose.jpg"
      end


      it "use custom urls if configured" do
        storage = Spontaneous::Media::Store::Cloud.new("s3", @aws_credentials.merge({
          :public_host => "http://media.example.com",
        }), @bucket_name)
        storage.to_url(@path).must_equal "http://media.example.com/0003/0567/rose.jpg"
      end

      it 'gives valid s3 urls for different regions' do
        storage = Spontaneous::Media::Store::Cloud.new("s3", @aws_credentials.merge({
          region: "eu-west-1"
        }), @bucket_name)
        storage.to_url(@path).must_equal "https://media.example.com.s3-eu-west-1.amazonaws.com/0003/0567/rose.jpg"
      end

      it 'allows for providing a direct URL mapper proc' do
        storage = Spontaneous::Media::Store::Cloud.new("s3", @aws_credentials.merge({
          url_mapper: proc { |path| "http://wallowig.com#{path}" }
        }), @bucket_name)
        storage.to_url(@path).must_equal "http://wallowig.com/0003/0567/rose.jpg"
      end
    end
  end
end
