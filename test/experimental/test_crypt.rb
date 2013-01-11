# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'benchmark'

class CryptTest < MiniTest::Spec
  Crypt = Spontaneous::Crypt

  def setup
    Crypt.default_version
  end

  context "versions" do
    should "be listable" do
      Crypt.versions.should == [Crypt::Version::Fake, Crypt::Version::SHALegacy, Crypt::Version::BCrypt201301]
    end

    should "choose the most up-to-date as the current" do
      Crypt.current.should == Crypt::Version::BCrypt201301
    end

    should "be directly loadable" do
      Crypt.version(201102).should == Crypt::Version::SHALegacy
    end

    should "be configurable" do
      Crypt.force_version(0)
      Crypt.current.should == Crypt::Version::Fake
    end
  end

  context "fake version" do
    setup do
      @pass = "abcdef"
    end
    should "have a version of 0" do
      Crypt::Version::SHALegacy.version.should == 201102
    end
    should "be creatable from a pasword" do
      hash = Crypt::Version::Fake.create(@pass)
      Crypt.new(@pass, hash).valid?.should be_true
    end
    should "not report that it should be upgraded" do
      hash = Crypt::Version::Fake.create(@pass)
      auth = Crypt.new(@pass, hash)
      auth.valid?.should be_true
      auth.outdated?.should be_false
      auth.needs_upgrade?.should be_false
    end
  end

  context "legacy version" do
    setup do
      @pass = "abcdef"
      @salt = "aaaaaa"
      @sha  = Crypt::Version::SHALegacy.sha(@salt, @pass)
    end

    should "have a version of 201102" do
      Crypt::Version::SHALegacy.version.should == 201102
    end

    should "be creatable from a pasword & salt" do
      hash = Crypt::Version::SHALegacy.create(@sha, @salt)
      hash.should =~ /^201102%aaaaaa:\$2a\$13\$/
      Crypt.new(@pass, hash).valid?.should be_true
    end

    should "report that it should be upgraded" do
      hash = Crypt::Version::SHALegacy.create(@sha, @salt)
      auth = Crypt.new(@pass, hash)
      auth.valid?.should be_true
      auth.outdated?.should be_true
      auth.needs_upgrade?.should be_true
    end

    should "upgrade to the current implementation" do
      hash = Crypt::Version::SHALegacy.create(@sha, @salt)
      auth = Crypt.new(@pass, hash)
      new_hash  = auth.upgrade
      new_auth = Crypt.new(@pass, new_hash)
      new_auth.outdated?.should be_false
      new_auth.valid?.should be_true
    end
  end

  context "password creation" do
    setup do
      @password = "abcdefg"
    end

    should "be verifiable" do
      hash = Crypt::hash(@password)
      Crypt.new(@password, hash).valid?.should be_true
    end

    should "use the latest version" do
      hash = Crypt::hash(@password)
      version, _ = Crypt.version_split(hash)
      version.should == Crypt.current.version
    end

    should "take at least half a second to compute" do
      hash = nil
      bm = Benchmark.measure { hash = Crypt::hash(@password) }
      bm.real.should >= 0.5
      bm = Benchmark.measure { Crypt::valid?(@password, hash) }
      bm.real.should >= 0.5
    end
  end
  context "users" do
    setup do
      S::Permissions::User.delete
      @pass = "abcdefghijklm"
      @attrs = {:login => "test", :email => "test@example.com", :name => "Test User", :password => @pass}
      @user = S::Permissions::User.new(@attrs)
      @user.save
    end

    teardown do
      S::Permissions::User.delete
    end

    should "use the current crypt implementation to hash their passwords" do
      hash = @user.crypted_password

      auth = Crypt.new(@pass, hash)
      auth.valid?.should be_true
    end

    should "authenticate successfully" do
      result = Spontaneous::Permissions::User.authenticate(@attrs[:login], @pass)
      result.must_be_instance_of S::Permissions::AccessKey
    end

    should "fail to authenticate with incorrect password" do
      result = Spontaneous::Permissions::User.authenticate(@attrs[:login], @pass + "x")
      result.should be_nil
    end

    should "transparently upgrade the auth version if outdated" do
      salt = "aaaaaaaa"
      sha  = Crypt::Version::SHALegacy.sha(salt, @pass)
      hash = Crypt::Version::SHALegacy.create(sha, salt)
      @user.model.filter(:id => @user.id).update(:crypted_password => hash)
      @user.reload
      auth = Crypt.new(@pass, @user.crypted_password)
      assert auth.outdated?, "Auth should be outdated"
      result = Spontaneous::Permissions::User.authenticate(@attrs[:login], @pass)
      result.must_be_instance_of S::Permissions::AccessKey
      @user.reload
      auth = Crypt.new(@pass, @user.crypted_password)
      assert !auth.outdated?, "Auth should have upgraded"
      result = Spontaneous::Permissions::User.authenticate(@attrs[:login], @pass)
      result.must_be_instance_of S::Permissions::AccessKey
    end
  end
end
