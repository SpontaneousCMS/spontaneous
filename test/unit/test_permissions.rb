# encoding: UTF-8

require 'test_helper'


class PermissionsTest < MiniTest::Spec

  def setup
    Permissions::UserLevel.reset!
    Permissions::UserLevel.level_file = File.expand_path('../../fixtures/permissions', __FILE__) / 'config/user_levels.yml'
  end

  def teardown
    Permissions::AccessGroup.delete
    Permissions::AccessKey.delete
    Permissions::User.delete
  end

  context "Permissions" do
    should "be able to generate random strings of any length" do
      (2..256).each do |length|
        s1 = Permissions.random_string(length)
        s2 = Permissions.random_string(length)
        s1.length.should == length
        s2.length.should == length
        s1.should_not == s2
      end
    end
  end
  context "Levels" do
    setup do
    end
    teardown do
    end

    should "always have a level of :none/0" do
      Permissions::UserLevel.none.should == Permissions::UserLevel::None
      Permissions::UserLevel[:none].should == Permissions::UserLevel.none
      Permissions::UserLevel['none'].should == Permissions::UserLevel.none
    end

    should "load from the config/user_levels.yml file" do
      Permissions::UserLevel[:editor].must_be_instance_of(Permissions::UserLevel::Level)
      Permissions::UserLevel['editor'].must_be_instance_of(Permissions::UserLevel::Level)
      Permissions::UserLevel['admin'].must_be_instance_of(Permissions::UserLevel::Level)
      Permissions::UserLevel['designer'].must_be_instance_of(Permissions::UserLevel::Level)
    end

    should "provide a sorted list of all levels" do
      Permissions::UserLevel.all.should == [:none, :editor, :admin, :designer, :root]
    end
    should "provide a list of all levels <= provided level" do
      Permissions::UserLevel.all(:editor).should == [:none, :editor]
      Permissions::UserLevel.all(:designer).should == [:none, :editor, :admin, :designer]
    end

    should "have a root level" do
      Permissions::UserLevel.root.should == Permissions::UserLevel::Root
    end

    should "have a root level that is always greater than other levels" do
      Permissions::UserLevel.root.should > Permissions::UserLevel['designer']
      Permissions::UserLevel.root.should >= Permissions::UserLevel['designer']
      Permissions::UserLevel.root.should > Permissions::UserLevel::Root
      Permissions::UserLevel.root.should >= Permissions::UserLevel::Root
      Permissions::UserLevel[:root].should == Permissions::UserLevel::Root
    end
    # should "map id to name"
    should "work with > operator" do
      Permissions::UserLevel[:admin].should > Permissions::UserLevel[:editor]
      Permissions::UserLevel[:editor].should > Permissions::UserLevel[:none]
    end
    should "work with >= operator" do
      Permissions::UserLevel[:admin].should >= Permissions::UserLevel[:admin]
      Permissions::UserLevel[:editor].should >= Permissions::UserLevel[:editor]
    end

    should "return a minimum level > none" do
      Permissions::UserLevel.minimum.should == Permissions::UserLevel.editor
    end
    should "have a valid string representation" do
      Permissions::UserLevel[:editor].to_s.should == 'editor'
      Permissions::UserLevel[:none].to_s.should == 'none'
      Permissions::UserLevel[:root].to_s.should == 'root'
      Permissions::UserLevel[:designer].to_s.should == 'designer'
    end

    should "have configurable level above which you have access to the publishing mechanism" do
      Permissions::UserLevel[:none].can_publish?.should be_false
      Permissions::UserLevel[:editor].can_publish?.should be_false
      Permissions::UserLevel[:admin].can_publish?.should be_false
      Permissions::UserLevel[:designer].can_publish?.should be_true
      Permissions::UserLevel[:root].can_publish?.should be_true
    end
  end

  context "Users" do
    setup do
      @now = Time.now
      Time.stubs(:now).returns(@now)
      @valid = {
        :name => "A Person",
        :email => "person@example.org",
        :login => "person",
        :password => "xxxxxx",
        :password_confirmation => "xxxxxx"
      }
    end

    teardown do
    end

    should "be creatable with valid params" do
      user = Permissions::User.new(@valid)
      user.save.must_be_instance_of(Permissions::User)
      user.valid?.should be_true
    end

    should "validate name" do
      user = Permissions::User.new(@valid.merge(:name => ""))
      user.save.should be_nil
      user.valid?.should be_false
      user.errors[:name].should_not be_blank
    end

    should "validate presence of email address" do
      user = Permissions::User.new(@valid.merge(:email => ""))
      user.save
      user.valid?.should be_false
      user.errors[:email].should_not be_blank
    end

    should "validate format of email address" do
      user = Permissions::User.new(@valid.merge(:email => "invalid.email.address"))
      user.save
      user.valid?.should be_false
      user.errors[:email].should_not be_blank
    end

    should "validate presence of login" do
      user = Permissions::User.new(@valid.merge(:login => ""))
      user.save
      user.valid?.should be_false
      user.errors[:login].should_not be_blank
    end

    should "validate length of login" do
      user = Permissions::User.new(@valid.merge(:login => "xx"))
      user.save
      user.valid?.should be_false
      user.errors[:login].should_not be_blank
    end

    should "reject duplicate logins" do
      user1 = Permissions::User.create(@valid)
      user2 = Permissions::User.new(@valid)
      user2.save
      user2.valid?.should be_false
      user2.errors[:login].should_not be_blank
    end

    should "require a non-blank password & password_confirmation" do
      user = Permissions::User.new(@valid.merge(:password => "", :password_confirmation => ""))
      user.save
      user.valid?.should be_false
      user.errors[:password].should_not be_blank
    end

    should "require a matching password & password_confirmation" do
      user = Permissions::User.new(@valid.merge(:password => "sdfsddfsdf", :password_confirmation => "sdf"))
      user.save
      user.valid?.should be_false
      user.errors[:password_confirmation].should_not be_blank
    end

    should "require passwords to be at least 6 characters" do
      user = Permissions::User.new(@valid.merge(:password => "12345", :password_confirmation => "12345"))
      user.save
      user.valid?.should be_false
      user.errors[:password].should_not be_blank
    end


    should "have a random salt" do
      user1 = Permissions::User.create(@valid)
      user2 = Permissions::User.create(@valid.merge(:login => "person2"))
      user1.salt.should_not be_blank
      user2.salt.should_not be_blank
      user1.salt.should_not == user2.salt
    end

    context "who are valid" do
      setup do
        @user = Permissions::User.create(@valid)
        @user.reload
      end

      should "have a created_at date" do
        @user.created_at.to_i.should == @now.to_i
      end

      should "have an associated 'invisible' group" do
        @user.group.must_be_instance_of(Permissions::AccessGroup)
        @user.group.invisible?.should be_true
        @user.group.level.should == Permissions::UserLevel::None
      end

      # the following actually works on the associated silent group
      should "default to a user level of Permissions::UserLevel.minimum" do
        @user.level.should == Permissions::UserLevel.none
      end

      should "have a settable user level" do
        @user.update(:level => Permissions::UserLevel[:root])
        @user.reload.level.should == Permissions::UserLevel.root
      end

      should "have a list of groups it belongs to" do
        @user.memberships.should == [@user.group]
      end

      should "be able to login with right login/password combination" do
        key = Permissions::User.authenticate(@user.login, @user.password)
        key.user.id.should == @user.id
        key = Permissions::User.authenticate(@user.login, "wrong password")
        key.should be_nil
      end

      should "have a last login date" do
        @user.last_login_at.should be_nil
        key = Permissions::User.authenticate(@user.login, @user.password)
        @user.reload.last_login_at.to_i.should == @now.to_i
      end

      should "generate a new access key on successful login" do
        @user.access_keys.should be_blank
        key = Permissions::User.authenticate(@user.login, @user.password)
        @user.reload.access_keys.length.should == 1
        @user.access_keys.first.created_at.to_i.should == @now.to_i
        @user.access_keys.first.last_access_at.to_i.should == @now.to_i
      end

      should "have a list of access keys" do
        @user.access_keys.must_be_instance_of(Array)
      end

      should "be blockable" do
        @user.update(:disabled => true)
        key = Permissions::User.authenticate(@user.login, @user.password)
        key.should be_nil
      end

      should "be able to belong to more than one group" do
        group1 = Permissions::AccessGroup.create(:name => "Group 1")
        group2 = Permissions::AccessGroup.create(:name => "Group 2")
        @user.add_group(group1)
        @user.add_group(group2)
        @user.groups.length.should == 2
        group1.members.should == [@user]
        group2.members.should == [@user]
      end

      should "return the right user level for a piece of content" do
        page = Page.create
        @user.update(:level => Permissions::UserLevel.admin)
        @user.access_selector.should == "*"
        @user.level_for(page).should == Permissions::UserLevel.admin
      end

      should "return the highest access level when multiple exist" do
        page = Page.create
        @user.update(:level => Permissions::UserLevel.none)
        group1 = Permissions::AccessGroup.create(:name => "Group 1", :level => Permissions::UserLevel.admin)
        group2 = Permissions::AccessGroup.create(:name => "Group 1", :level => Permissions::UserLevel.editor)
        group1.add_member(@user)
        group2.add_member(@user)
        @user.level_for(page).should == Permissions::UserLevel.admin
      end
    end
  end

  context "access keys" do
    setup do
      @now = Time.now
      Time.stubs(:now).returns(@now)
      @valid = {
        :name => "A Person",
        :email => "person@example.org",
        :login => "person",
        :password => "xxxxxx",
        :password_confirmation => "xxxxxx"
      }
    end

    teardown do
    end

    should "have a generated key_id" do
      key1 = Permissions::AccessKey.create
      key1.key_id.length.should == 44
      key2 = Permissions::AccessKey.create
      key2.key_id.length.should == 44
      key1.key_id.should_not == key2.key_id
    end

    should "allow authentication of a user" do
      key1 = Permissions::AccessKey.create
      key2 = Permissions::AccessKey.authenticate(key1.key_id)
      key1.id.should == key2.id
    end

    should "update timestamps when authenticated" do
      user = Permissions::User.create(@valid)
      key1 = Permissions::AccessKey.create(:user_id => user.id)
      Time.stubs(:now).returns(@now + 1000)
      key2 = Permissions::AccessKey.create(:user_id => user.id)
      key3 = Permissions::AccessKey.authenticate(key2.key_id)
      key2.id.should == key3.id
      key2.reload.last_access_at.to_i.should == (@now+1000).to_i
      key2.user.last_access_at.to_i.should == (@now+1000).to_i
    end

    should "be guaranteed unique" do
      Permissions.stubs(:random_string).returns("xxxx")
      key1 = Permissions::AccessKey.create()
      lambda { Permissions::AccessKey.create() }.must_raise(Sequel::DatabaseError)
    end

    should "have a creation date" do
      key1 = Permissions::AccessKey.create
      key1.created_at.to_i.should == @now.to_i
    end

    should "have a source IP address"

    should "retrieve their associated user" do
      user = Permissions::User.create(@valid)
      key1 = Permissions::AccessKey.create(:user_id => user.id)
      key1.reload.user.should == user
    end

    should "be disabled when user blocked" do
      user = Permissions::User.create(@valid)
      key1 = Permissions::AccessKey.create(:user_id => user.id)
      user.update(:disabled => true)
      key3 = Permissions::AccessKey.authenticate(key1.key_id)
      key3.should be_nil
    end
  end



  context "Groups" do
    setup do
      @valid_group = {
        :name => "Some People"
      }
    end

    teardown do
    end

    should "always have a name" do
      group = Permissions::AccessGroup.new(@valid_group.merge(:name => ""))
      group.valid?.should be_false
      group.errors[:name].should_not be_blank
    end

    should "default to a user level of :none" do
      group = Permissions::AccessGroup.create(@valid_group)
      group.reload
      group.level.should == Permissions::UserLevel::None
    end

    # disabling a user and blocking a group are different
    # if you disable a user you disable their login
    # if you block a group they belong to you remove the permissions
    # granted by that group but you aren't stopping them from logging in
    should "be blockable" do
      group = Permissions::AccessGroup.create(@valid_group.merge(:level => Permissions::UserLevel.admin))
      group.level.should == Permissions::UserLevel.admin
      group.update(:disabled => true)
      group.level.should == Permissions::UserLevel.none
    end

    should "default to applying to the whole site" do
      group = Permissions::AccessGroup.create(@valid_group)
      group.access_selector.should == "*"
    end

    should "return the right user level for a piece of content" do
      group = Permissions::AccessGroup.create(@valid_group)
      page = Page.create
      group.update(:level => Permissions::UserLevel.admin)
      group.access_selector.should == "*"
      group.level_for(page).should == Permissions::UserLevel.admin
    end
  end

  context "Guards" do
    setup do
      @visitor = Permissions::User.create(:email => "visitor@example.com", :login => "visitor", :name => "visitor", :password => "visitorpass", :password_confirmation => "visitorpass")
      @editor = Permissions::User.create(:email => "editor@example.com", :login => "editor", :name => "editor", :password => "editorpass", :password_confirmation => "editorpass")
      @admin = Permissions::User.create(:email => "admin@example.com", :login => "admin", :name => "admin", :password => "adminpass", :password_confirmation => "adminpass")
      @root = Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass", :password_confirmation => "rootpass")
      @editor.update(:level => Permissions::UserLevel.editor)
      @admin.update(:level => Permissions::UserLevel.admin)
      @root.update(:level => Permissions::UserLevel.root)

      class ::C < Content; end

      C.field :editor_level, :user_level => :editor
      C.field :admin_level, :user_level => :admin
      C.field :root_level, :user_level => :root
      C.field :mixed_level, :read_level => :editor, :write_level => :root
      C.field :default_level

      C.box :editor_level, :user_level => :editor do
        field :editor_level, :user_level => :editor
        field :admin_level, :user_level => :admin
        field :root_level, :user_level => :root
        field :mixed_level, :read_level => :editor, :write_level => :root
        field :default_level

        allow :D, :user_level => :editor
        allow :C, :user_level => :admin
      end

      C.box :admin_level, :user_level => :admin do
        field :editor_level, :user_level => :editor
        field :admin_level, :user_level => :admin
        field :root_level, :user_level => :root
        field :mixed_level, :read_level => :editor, :write_level => :root
        field :default_level

        allow :C, :user_level => :admin
      end

      C.box :root_level, :user_level => :root do
        field :editor_level, :user_level => :editor
        field :admin_level, :user_level => :admin
        field :root_level, :user_level => :root
        field :mixed_level, :read_level => :editor, :write_level => :root
        field :default_level

        allow :C, :user_level => :root
      end

      C.box :mixed_level, :read_level => :editor, :write_level => :root do
        field :editor_level, :user_level => :editor
        field :admin_level, :user_level => :admin
        field :root_level, :user_level => :root
        field :mixed_level, :read_level => :editor, :write_level => :root
        field :default_level

        allow :C, :user_level => :editor
      end

      C.box :default_level do
        field :editor_level, :user_level => :editor
        field :admin_level, :user_level => :admin
        field :root_level, :user_level => :root
        field :mixed_level, :read_level => :editor, :write_level => :root
        field :default_level

        allow :C
      end

      class ::D < Content; end
      @i = C.new
    end

    teardown do
      Object.send(:remove_const, :C)
      Object.send(:remove_const, :D)
    end

    should "protect field reads" do
      # without user (e.g. terminal/console access) everything is always
      # possible
      @i.field_readable?(:editor_level).should be_true
      @i.field_readable?(:admin_level).should be_true
      @i.field_readable?(:root_level).should be_true
      @i.field_readable?(:mixed_level).should be_true
      @i.field_readable?(:default_level).should be_true

      Permissions.with_user(@visitor) do
        @i.field_readable?(:editor_level).should be_false
        @i.field_readable?(:admin_level).should be_false
        @i.field_readable?(:root_level).should be_false
        @i.field_readable?(:mixed_level).should be_false
        @i.field_readable?(:default_level).should be_true
      end
      Permissions.with_user(@editor) do
        @i.field_readable?(:editor_level).should be_true
        @i.field_readable?(:admin_level).should be_false
        @i.field_readable?(:root_level).should be_false
        @i.field_readable?(:mixed_level).should be_true
        @i.field_readable?(:default_level).should be_true
      end
      Permissions.with_user(@admin) do
        @i.field_readable?(:editor_level).should be_true
        @i.field_readable?(:admin_level).should be_true
        @i.field_readable?(:root_level).should be_false
        @i.field_readable?(:mixed_level).should be_true
        @i.field_readable?(:default_level).should be_true
      end
      Permissions.with_user(@root) do
        @i.field_readable?(:editor_level).should be_true
        @i.field_readable?(:admin_level).should be_true
        @i.field_readable?(:root_level).should be_true
        @i.field_readable?(:mixed_level).should be_true
        @i.field_readable?(:default_level).should be_true
      end
    end

    should "protect field writes" do
      # without user (e.g. terminal/console access) everything is always
      # possible
      @i.field_writable?(:editor_level).should be_true
      @i.field_writable?(:admin_level).should be_true
      @i.field_writable?(:root_level).should be_true
      @i.field_writable?(:mixed_level).should be_true
      @i.field_writable?(:default_level).should be_true

      Permissions.with_user(@visitor) do
        @i.field_writable?(:editor_level).should be_false
        @i.field_writable?(:admin_level).should be_false
        @i.field_writable?(:root_level).should be_false
        @i.field_writable?(:mixed_level).should be_false
        @i.field_writable?(:default_level).should be_false
      end
      Permissions.with_user(@editor) do
        @i.field_writable?(:editor_level).should be_true
        @i.field_writable?(:admin_level).should be_false
        @i.field_writable?(:root_level).should be_false
        @i.field_writable?(:mixed_level).should be_false
        @i.field_writable?(:default_level).should be_true
      end
      Permissions.with_user(@admin) do
        @i.field_writable?(:editor_level).should be_true
        @i.field_writable?(:admin_level).should be_true
        @i.field_writable?(:root_level).should be_false
        @i.field_writable?(:mixed_level).should be_false
        @i.field_writable?(:default_level).should be_true
      end
      Permissions.with_user(@root) do
        @i.field_writable?(:editor_level).should be_true
        @i.field_writable?(:admin_level).should be_true
        @i.field_writable?(:root_level).should be_true
        @i.field_writable?(:mixed_level).should be_true
        @i.field_writable?(:default_level).should be_true
      end
    end

    should "protect box reads" do
      @i.box_readable?(:editor_level).should be_true
      @i.box_readable?(:admin_level).should be_true
      @i.box_readable?(:root_level).should be_true
      @i.box_readable?(:mixed_level).should be_true
      @i.box_readable?(:default_level).should be_true

      Permissions.with_user(@visitor) do
        @i.box_readable?(:editor_level).should be_false
        @i.box_readable?(:admin_level).should be_false
        @i.box_readable?(:root_level).should be_false
        @i.box_readable?(:mixed_level).should be_false
        @i.box_readable?(:default_level).should be_true
      end
      Permissions.with_user(@editor) do
        @i.box_readable?(:editor_level).should be_true
        @i.box_readable?(:admin_level).should be_false
        @i.box_readable?(:root_level).should be_false
        @i.box_readable?(:mixed_level).should be_true
        @i.box_readable?(:default_level).should be_true
      end
      Permissions.with_user(@admin) do
        @i.box_readable?(:editor_level).should be_true
        @i.box_readable?(:admin_level).should be_true
        @i.box_readable?(:root_level).should be_false
        @i.box_readable?(:mixed_level).should be_true
        @i.box_readable?(:default_level).should be_true
      end
      Permissions.with_user(@root) do
        @i.box_readable?(:editor_level).should be_true
        @i.box_readable?(:admin_level).should be_true
        @i.box_readable?(:root_level).should be_true
        @i.box_readable?(:mixed_level).should be_true
        @i.box_readable?(:default_level).should be_true
      end
    end
    should "protect box writes" do
      @i.box_writable?(:editor_level).should be_true
      @i.box_writable?(:admin_level).should be_true
      @i.box_writable?(:root_level).should be_true
      @i.box_writable?(:mixed_level).should be_true
      @i.box_writable?(:default_level).should be_true

      Permissions.with_user(@visitor) do
        @i.box_writable?(:editor_level).should be_false
        @i.box_writable?(:admin_level).should be_false
        @i.box_writable?(:root_level).should be_false
        @i.box_writable?(:mixed_level).should be_false
        @i.box_writable?(:default_level).should be_false
      end
      Permissions.with_user(@editor) do
        @i.box_writable?(:editor_level).should be_true
        @i.box_writable?(:admin_level).should be_false
        @i.box_writable?(:root_level).should be_false
        @i.box_writable?(:mixed_level).should be_false
        @i.box_writable?(:default_level).should be_true
      end
      Permissions.with_user(@admin) do
        @i.box_writable?(:editor_level).should be_true
        @i.box_writable?(:admin_level).should be_true
        @i.box_writable?(:root_level).should be_false
        @i.box_writable?(:mixed_level).should be_false
        @i.box_writable?(:default_level).should be_true
      end
      Permissions.with_user(@root) do
        @i.box_writable?(:editor_level).should be_true
        @i.box_writable?(:admin_level).should be_true
        @i.box_writable?(:root_level).should be_true
        @i.box_writable?(:mixed_level).should be_true
        @i.box_writable?(:default_level).should be_true
      end
    end

    should "serialise only things in class viewable by the current user" do
      expected = [
        ["editor_level", true],
        ["admin_level", true],
        ["root_level", true],
        ["mixed_level", true],
        ["default_level", true]
      ]
      C.to_hash[:fields].map { |f| [f[:name], f[:writable]] }.should == expected
      C.to_hash[:boxes].map { |f| [f[:name], f[:writable]] }.should == expected
      C.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.should == [
        ["editor_level", expected],
        ["admin_level", expected],
        ["root_level", expected],
        ["mixed_level", expected],
        ["default_level", expected]
      ]

      Permissions.with_user(@root) do
        C.to_hash[:fields].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.should == [
          ["editor_level", expected],
          ["admin_level", expected],
          ["root_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      end

      Permissions.with_user(@visitor) do
        expected = [
          ["default_level", false]
        ]
        C.to_hash[:fields].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.should == [
          ["default_level", expected ]
        ]
      end

      Permissions.with_user(@editor) do
        expected = [
          ["editor_level", true],
          ["mixed_level", false],
          ["default_level", true]
        ]
        C.to_hash[:fields].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.should == [
          ["editor_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      end

      Permissions.with_user(@admin) do
        expected = [
          ["editor_level", true],
          ["admin_level", true],
          ["mixed_level", false],
          ["default_level", true]
        ]
        C.to_hash[:fields].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |f| [f[:name], f[:writable]] }.should == expected
        C.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.should == [
          ["editor_level", expected],
          ["admin_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      end
    end

    should "only list allowed types addable by the user" do
      expected = [
        ["editor_level", ["D", "C"]],
        ["admin_level", ["C"]],
        ["root_level", ["C"]],
        ["mixed_level", ["C"]],
        ["default_level", ["C"]]
      ]
      C.to_hash[:boxes].map { |b| [b[:name], b[:allowed_types]] }.should == expected

      Permissions.with_user(@root) do
        C.to_hash[:boxes].map { |b| [b[:name], b[:allowed_types]] }.should == expected
      end
      Permissions.with_user(@visitor) do
        expected = [
          ["default_level", []]
        ]
        C.to_hash[:boxes].map { |b| [b[:name], b[:allowed_types]] }.should == expected
      end
      Permissions.with_user(@editor) do
        expected = [
          ["editor_level", ["D"]],
          ["mixed_level", []],
          ["default_level", ["C"]]
        ]
        C.to_hash[:boxes].map { |b| [b[:name], b[:allowed_types]] }.should == expected
      end
      Permissions.with_user(@admin) do
        expected = [
          ["editor_level", ["D", "C"]],
          ["admin_level", ["C"]],
          ["mixed_level", []],
          ["default_level", ["C"]]
        ]
        C.to_hash[:boxes].map { |b| [b[:name], b[:allowed_types]] }.should == expected
      end
    end

    should "serialise only things in instance viewable by the current user" do
      expected = [
        "editor_level",
        "admin_level",
        "root_level",
        "mixed_level",
        "default_level"
      ]
      @i.to_hash[:boxes].map { |f| f[:name] }.should == expected
      @i.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.should == [
        ["editor_level", expected],
        ["admin_level", expected],
        ["root_level", expected],
        ["mixed_level", expected],
        ["default_level", expected]
      ]
      Permissions.with_user(@root) do
        @i.to_hash[:boxes].map { |f| f[:name] }.should == expected
        @i.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.should == [
          ["editor_level", expected],
          ["admin_level", expected],
          ["root_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      end

      Permissions.with_user(@visitor) do
        @i.to_hash[:boxes].map { |f| f[:name] }.should == [
          "default_level"
        ]
        @i.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.should == [
          ["default_level", ["default_level"]]
        ]
      end

      Permissions.with_user(@editor) do
        expected = [
          "editor_level",
          "mixed_level",
          "default_level"
        ]
        @i.to_hash[:boxes].map { |f| f[:name] }.should == expected
        @i.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.should == [
          ["editor_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      end

      Permissions.with_user(@admin) do
        expected = [
          "editor_level",
          "admin_level",
          "mixed_level",
          "default_level"
        ]
        @i.to_hash[:boxes].map { |f| f[:name] }.should == expected
        @i.to_hash[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.should == [
          ["editor_level", expected],
          ["admin_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      end

    end
  end
end
