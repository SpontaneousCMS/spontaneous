# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

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
      @storage.url.should == "/media"
    end
    should "test for locality" do
      @storage.local?.should be_true
    end

    should "provide a list of local storage backends" do
      @site.local_storage.should == [@storage]
    end
  end
  context "cloud storage" do
  end
end
