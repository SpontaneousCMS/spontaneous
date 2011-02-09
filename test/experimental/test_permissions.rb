# encoding: UTF-8

require 'test_helper'


class PermissionsTest < Test::Unit::TestCase

  context "Levels" do
    setup do
      UserLevel
      @pwd = Dir.pwd
      Dir.chdir(File.expand_path('../../fixtures/permissions', __FILE__))
      File.exists?('config/user_levels.yml').should be_true
    end
    teardown do
      Dir.chdir(@pwd)
    end
    should "always have a level of :none/0" do
      UserLevel.none.should == UserLevel::None
      UserLevel[:none].should == UserLevel.none
      UserLevel['none'].should == UserLevel.none
    end
    should "load from the config/user_levels.yml file" do
      UserLevel[:editor].should == 1
      UserLevel['editor'].should == 1
      UserLevel['admin'].should == 10
      UserLevel['designer'].should == 50
    end
    should "provide a sorted list of all levels" do
      UserLevel.all.should == [:none, :editor, :admin, :designer, :root]
    end
    should "provide a list of all levels <= provided level" do
      UserLevel.all(:editor).should == [:none, :editor]
      UserLevel.all(:designer).should == [:none, :editor, :admin, :designer]
    end

    should "have a root level" do
      UserLevel.root.should == UserLevel::Root
    end

    should "have a root level that is always greater than other levels" do
      UserLevel.root.should > UserLevel['designer']
      UserLevel.root.should >= UserLevel['designer']
      UserLevel.root.should > UserLevel::Root
      UserLevel.root.should >= UserLevel::Root
      UserLevel[:root].should == UserLevel::Root
    end
    # should "map id to name"
    should "work with > operator" do
      UserLevel[:admin].should > UserLevel[:editor]
      UserLevel[:editor].should > UserLevel[:none]
    end
    should "work with >= operator" do
      UserLevel[:admin].should >= UserLevel[:admin]
      UserLevel[:editor].should >= UserLevel[:editor]
    end
  end

  context "Users" do
    should "validate name"
    should "validate email address"
    should "validate login"
    should "have a created_at date"
    should "have an associated 'invisible' group"
    # the following actually works on the associated silent group
    should "default to a user level of :none"
    should "have a settable user level"
    should "have their own group"
    should "be blockable"
    should "be able to belong to more than one group"
    should "be able to login with right login/password combination"
    should "have a last login date"
    should "have a login count"
    should "generate a new access key on successful login"
    should "have a list of access keys"
    should "be able to remove a specific access key"
  end

  context "access keys" do
    should "be guaranteed unique"
    should "have a creation date"
    should "have an access date"
    should "have a source IP address"
    should "retrieve their associated user"
    should "be disabled when user blocked"
  end



  context "Groups" do
    should "always have a name"
    should "be blockable"
    should "have a list of users"
    should "have an associated user level"
    should "default to a user level of :none/0"
    should "default to applying to the whole site"
  end

end
