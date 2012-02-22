# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'fog'

class StorageTest < MiniTest::Spec
  def setup
    @site = setup_site
    @config_dir = File.expand_path("../../fixtures/storage", __FILE__)
  end

  def teardown
    teardown_site
  end

  context "local storage" do
    setup do
      @site.paths.add :config, File.expand_path(@config_dir / "default", __FILE__)
      @site.load_config!
      # sanity check
      @site.config.test_setting.should be_true
      @storage = @site.storage
    end
    should "be the default" do
      @storage.must_be_instance_of Spontaneous::Storage::Local
    end
    should "have the right base url" do
      @storage.public_url("test.jpg").should == "/media/test.jpg"
    end
    should "test for locality" do
      @storage.local?.should be_true
    end

    should "provide a list of local storage backends" do
      @site.local_storage.should == [@storage]
    end
  end
  context "cloud storage" do
    setup do
      @bucket_name = "media.example.com"
      @aws_credentials = {
        :provider=>"AWS",
        :aws_secret_access_key=>"SECRET_ACCESS_KEY",
        :aws_access_key_id=>"ACCESS_KEY_ID"
      }
      ::Fog.mock!
      @connection = Fog::Storage.new(@aws_credentials)
      @connection.directories.create(:key => @bucket_name)
      @site.paths.add :config, File.expand_path(@config_dir / "cloud", __FILE__)
      @site.load_config!
      # sanity check
      @site.config.test_setting.should be_true
      @storage = @site.storage
    end

    should "be detected by configuration" do
      @storage.must_be_instance_of Spontaneous::Storage::Cloud
    end

    should "have the correct bucket name" do
      @storage.bucket_name.should == "media.example.com"
    end

    should "not test as local" do
      @storage.local?.should be_false
    end

    context "remote files" do
      setup do
        @existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
        @media_path = %w(0003 0567 rose.jpg)
      end
      should "have the correct mimetype" do
        file = @storage.copy(@existing_file, @media_path, "image/jpeg")
        file.content_type.should == "image/jpeg"
      end

      should "be given a far future expiry" do
        now = Time.now
        Time.stubs(:now).returns(now)
        file = @storage.copy(@existing_file, @media_path, "image/jpeg")
        file.expires.should == (now + 20.years)
      end

      should "be set as publicly visible" do
        file = @storage.copy(@existing_file, @media_path, "image/jpeg")
        acl = file.connection.get_object_acl(file.directory.key, file.key).body['AccessControlList']
        perms = acl.detect {|grant| grant['Grantee']['URI'] == 'http://acs.amazonaws.com/groups/global/AllUsers' }
        perms["Permission"].should == "READ"
      end

    end

    context "public urls" do
      setup do
        existing_file = File.expand_path("../../fixtures/images/rose.jpg", __FILE__)
        @media_path = %w(0003 0567 rose.jpg)
        @storage.copy(existing_file, @media_path, "image/jpeg")
      end

      should "have the correct base url" do
        @storage.public_url(@media_path).should == "https://media.example.com.s3.amazonaws.com/0003-0567-rose.jpg"
      end


      should "use custom urls if configured" do
        storage = Spontaneous::Storage::Cloud.new(@aws_credentials.merge({
          :public_host => "http://media.example.com",
        }), @bucket_name)
        storage.public_url(@media_path).should == "http://media.example.com/0003-0567-rose.jpg"
      end
    end
  end
end
