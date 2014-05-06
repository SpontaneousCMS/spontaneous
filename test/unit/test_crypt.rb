# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'benchmark'

describe "Crypt" do
  Crypt = Spontaneous::Crypt

  before do
    Crypt.default_version
  end

  describe "versions" do
    it "be listable" do
      Crypt.versions.must_equal [Crypt::Version::Fake, Crypt::Version::SHALegacy, Crypt::Version::BCrypt201301]
    end

    it "choose the most up-to-date as the current" do
      Crypt.current.must_equal Crypt::Version::BCrypt201301
    end

    it "be directly loadable" do
      Crypt.version(201102).must_equal Crypt::Version::SHALegacy
    end

    it "be configurable" do
      Crypt.force_version(0)
      Crypt.current.must_equal Crypt::Version::Fake
    end
  end

  describe "fake version" do
    before do
      @pass = "abcdef"
    end
    it "have a version of 0" do
      Crypt::Version::SHALegacy.version.must_equal 201102
    end
    it "be creatable from a pasword" do
      hash = Crypt::Version::Fake.create(@pass)
      assert Crypt.new(@pass, hash).valid?
    end
    it "not report that it should be upgraded" do
      hash = Crypt::Version::Fake.create(@pass)
      auth = Crypt.new(@pass, hash)
      assert auth.valid?
      refute auth.outdated?
      refute auth.needs_upgrade?
    end
  end

  describe "legacy version" do
    before do
      @pass = "abcdef"
      @salt = "aaaaaa"
      @sha  = Crypt::Version::SHALegacy.sha(@salt, @pass)
    end

    it "have a version of 201102" do
      Crypt::Version::SHALegacy.version.must_equal 201102
    end

    it "be creatable from a pasword & salt" do
      hash = Crypt::Version::SHALegacy.create(@sha, @salt)
      hash.must_match /^201102%aaaaaa:\$2a\$13\$/
      assert Crypt.new(@pass, hash).valid?
    end

    it "report that it should be upgraded" do
      hash = Crypt::Version::SHALegacy.create(@sha, @salt)
      auth = Crypt.new(@pass, hash)
      assert auth.valid?
      assert auth.outdated?
      assert auth.needs_upgrade?
    end

    it "upgrade to the current implementation" do
      hash = Crypt::Version::SHALegacy.create(@sha, @salt)
      auth = Crypt.new(@pass, hash)
      new_hash  = auth.upgrade
      new_auth = Crypt.new(@pass, new_hash)
      refute new_auth.outdated?
      assert new_auth.valid?
    end
  end

  describe "password creation" do
    before do
      @password = "abcdefg"
    end

    it "be verifiable" do
      hash = Crypt::hash_password(@password)
      assert Crypt.new(@password, hash).valid?
    end

    it "use the latest version" do
      hash = Crypt::hash_password(@password)
      version, _ = Crypt.version_split(hash)
      version.must_equal Crypt.current.version
    end

    it "take at least half a second to compute" do
      hash = nil
      bm = Benchmark.measure { hash = Crypt::hash_password(@password) }
      bm.real.must_be :>=, 0.5
      bm = Benchmark.measure { Crypt::valid?(@password, hash) }
      bm.real.must_be :>=, 0.5
    end
  end
  describe "users" do
    before do
      S::Permissions::User.delete
      @pass = "abcdefghijklm"
      @attrs = {:login => "test", :email => "test@example.com", :name => "Test User", :password => @pass}
      @user = S::Permissions::User.new(@attrs)
      @user.save
    end

    after do
      S::Permissions::User.delete
    end

    it "use the current crypt implementation to hash their passwords" do
      hash = @user.crypted_password

      auth = Crypt.new(@pass, hash)
      assert auth.valid?
    end

    it "authenticate successfully" do
      result = Spontaneous::Permissions::User.authenticate(@attrs[:login], @pass)
      result.must_be_instance_of S::Permissions::AccessKey
    end

    it "fail to authenticate with incorrect password" do
      result = Spontaneous::Permissions::User.authenticate(@attrs[:login], @pass + "x")
      result.must_be_nil
    end

    it "transparently upgrade the auth version if outdated" do
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
