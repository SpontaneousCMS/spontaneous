# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Permissions" do

  Permissions = Spontaneous::Permissions unless defined?(Permissions)

  before do
    @site = setup_site
    ::Content.delete
    Permissions::UserLevel.reset!
    @level_file = File.expand_path('../../fixtures/permissions/config/user_levels.yml', __FILE__)
    Permissions::UserLevel.stubs(:level_file).returns(@level_file)
  end

  after do
    teardown_site
    begin
    Permissions::AccessGroup.delete
    Permissions::AccessKey.delete
    Permissions::User.delete
    rescue => e
      # My uniqueness constraint test raises a db error which then causes
      # a pg transaction error that I can safely ignore
      unless e.class == Sequel::DatabaseError && e.message =~ /current transaction is aborted/
        raise
      end
    end
  end

  it "can generate random strings of any length" do
    (2..256).each do |length|
      s1 = Permissions.random_string(length)
      s2 = Permissions.random_string(length)
      s1.length.must_equal length
      s2.length.must_equal length
      s1.wont_equal s2
    end
  end

  describe "UserLevel" do
    it "always has a level of :none/0" do
      Permissions::UserLevel.none.must_equal Permissions::UserLevel::None
      Permissions::UserLevel[:none].must_equal Permissions::UserLevel.none
      Permissions::UserLevel['none'].must_equal Permissions::UserLevel.none
    end

    it "are loaded from the config/user_levels.yml file" do
      Permissions::UserLevel[:editor].must_be_instance_of(Permissions::UserLevel::Level)
      Permissions::UserLevel['editor'].must_be_instance_of(Permissions::UserLevel::Level)
      Permissions::UserLevel['admin'].must_be_instance_of(Permissions::UserLevel::Level)
      Permissions::UserLevel['designer'].must_be_instance_of(Permissions::UserLevel::Level)
    end

    it "provides a sorted list of all levels" do
      Permissions::UserLevel.all.map(&:to_sym).must_equal [:none, :editor, :admin, :designer, :root]
    end

    it "provides a list of all levels <= provided level" do
      Permissions::UserLevel.all(:editor).map(&:to_sym).must_equal [:none, :editor]
      Permissions::UserLevel.all(:designer).map(&:to_sym).must_equal [:none, :editor, :admin, :designer]
    end

    it "has a root level" do
      Permissions::UserLevel.root.must_equal Permissions::UserLevel::Root
    end

    it "has a root level that is always greater than other levels except root" do
      Permissions::UserLevel.root.must_be :>,  Permissions::UserLevel['designer']
      Permissions::UserLevel.root.must_be :>=, Permissions::UserLevel['designer']
      Permissions::UserLevel.root.wont_be :>,  Permissions::UserLevel::Root
      Permissions::UserLevel.root.must_be :>=, Permissions::UserLevel::Root
      Permissions::UserLevel[:root].must_equal Permissions::UserLevel::Root
    end

    it "works with > operator" do
      Permissions::UserLevel[:admin].must_be :>, Permissions::UserLevel[:editor]
      Permissions::UserLevel[:editor].must_be :>, Permissions::UserLevel[:none]
    end
    it "works with >= operator" do
      Permissions::UserLevel[:admin].must_be :>=, Permissions::UserLevel[:admin]
      Permissions::UserLevel[:editor].must_be :>=, Permissions::UserLevel[:editor]
    end

    it "returns a minimum level > none" do
      Permissions::UserLevel.minimum.must_equal Permissions::UserLevel.editor
    end
    it "has a valid string representation" do
      Permissions::UserLevel[:editor].to_s.must_equal 'editor'
      Permissions::UserLevel[:none].to_s.must_equal 'none'
      Permissions::UserLevel[:root].to_s.must_equal 'root'
      Permissions::UserLevel[:designer].to_s.must_equal 'designer'
    end

    it "has configurable level above which you have access to the publishing mechanism" do
      refute Permissions::UserLevel[:none].can_publish?
      refute Permissions::UserLevel[:editor].can_publish?
      refute Permissions::UserLevel[:admin].can_publish?
      assert Permissions::UserLevel[:designer].can_publish?
      assert Permissions::UserLevel[:root].can_publish?
    end

    it "has a developer flag" do
      refute Permissions::UserLevel[:none].developer?
      refute Permissions::UserLevel[:editor].developer?
      refute Permissions::UserLevel[:admin].developer?
      assert Permissions::UserLevel[:designer].developer?
      assert Permissions::UserLevel[:root].developer?
    end
  end

  describe "User" do
    before do
      @now = Time.now
      Time.stubs(:now).returns(@now)
      @valid = {
        :name => "A Person",
        :email => "person@example.org",
        :login => "person",
        :password => "xxxxxxxx"
      }
      @valid2 = {
        :name => "Another Person",
        :email => "person2@example.org",
        :login => "person2",
        :password => "xxxxxxxxxx"
      }
    end

    it "are retrievable as a list" do
      user1 = Permissions::User.create(@valid.merge(:level => S::Permissions[:editor]))
      user2 = Permissions::User.create(@valid2.merge(:level => S::Permissions[:admin]))
      user1.logged_in!("196.168.1.11")
      exported = Permissions::User.export(nil)
      exported[:users].must_equal [
        { :id => user1.id, :name => "A Person", :email => "person@example.org", :login => "person", :level => "editor",
          :keys => [:last_access_at => @now.httpdate, :last_access_ip => "196.168.1.11"], :disabled => false },
        { :id => user2.id, :name => "Another Person", :email => "person2@example.org", :login => "person2", :level => "admin", :disabled => false,
          :keys => [] }
      ]
      exported[:levels].must_equal [
        { :level => "none", :can_publish => false, :is_admin => false  },
        { :level => "editor", :can_publish => false, :is_admin => false  },
        { :level => "admin", :can_publish => false, :is_admin => true  },
        { :level => "designer", :can_publish => true, :is_admin => false  },
        { :level => "root", :can_publish => true, :is_admin => true  }
      ]
    end

    it "filters exported user list to remove users with a higher level" do
      user1 = Permissions::User.create(@valid.merge(:level => S::Permissions[:editor]))
      user2 = Permissions::User.create(@valid2.merge(:level => S::Permissions[:admin]))
      user3 = Permissions::User.create(@valid.merge(:login => "person3", :email => "person3@example.com", :level => S::Permissions[:root]))
      user1.logged_in!("196.168.1.11")
      exported = Permissions::User.export(user2)
      exported[:users].must_equal [
        { :id => user1.id, :name => "A Person", :email => "person@example.org", :login => "person", :level => "editor", :disabled => false,
          :keys => [:last_access_at => @now.httpdate, :last_access_ip => "196.168.1.11"] },
        { :id => user2.id, :name => "Another Person", :email => "person2@example.org", :login => "person2", :level => "admin", :disabled => false,
          :keys => [] }
      ]
      exported[:levels].must_equal [
        { :level => "none", :can_publish => false, :is_admin => false  },
        { :level => "editor", :can_publish => false, :is_admin => false  },
        { :level => "admin", :can_publish => false, :is_admin => true  },
      ]
    end

    it "is creatable with valid params" do
      user = Permissions::User.new(@valid)
      user.save.must_be_instance_of(Permissions::User)
      assert user.valid?
    end

    it "validates names" do
      user = Permissions::User.new(@valid.merge(:name => ""))
      user.save.must_be_nil
      refute user.valid?
      user.errors[:name].wont_be_empty
    end

    it "validates presence of email addresses" do
      user = Permissions::User.new(@valid.merge(:email => ""))
      user.save
      refute user.valid?
      user.errors[:email].wont_be_empty
    end

    it "validates format of email addresses" do
      user = Permissions::User.new(@valid.merge(:email => "invalid.email.address"))
      user.save
      refute user.valid?
      user.errors[:email].wont_be_empty
    end

    it "validates presence of logins" do
      user = Permissions::User.new(@valid.merge(:login => ""))
      user.save
      refute user.valid?
      user.errors[:login].wont_be_empty
    end

    it "validates length of logins" do
      user = Permissions::User.new(@valid.merge(:login => "xx"))
      user.save
      refute user.valid?
      user.errors[:login].wont_be_empty
    end

    it "rejects duplicate logins on creation" do
      user1 = Permissions::User.create(@valid)
      user2 = Permissions::User.new(@valid)
      user2.save
      refute user2.valid?
      user2.errors[:login].wont_be_empty
    end

    it "rejects duplicate logins on update" do
      user1 = Permissions::User.create(@valid)
      user2 = Permissions::User.create(@valid.merge(:login => "other"))
      user2.update_fields({:login => @valid[:login]}, [:login])
      refute user2.valid?
      user2.errors[:login].wont_be_empty
    end

    it "requires non-blank passwords" do
      user = Permissions::User.new(@valid.merge(:password => ""))
      user.save
      refute user.valid?
      user.errors[:password].wont_be_empty
    end

    it "requires passwords to be at least 8 characters" do
      user = Permissions::User.new(@valid.merge(:password => "1234567"))
      user.save
      refute user.valid?
      user.errors[:password].wont_be_empty
    end

    describe "Valid" do
      before do
        @user = Permissions::User.create(@valid)
        @user.reload
      end

      it "have a created_at date" do
        @user.created_at.to_i.must_equal @now.to_i
      end

      it "have an associated 'invisible' group" do
        @user.group.must_be_instance_of(Permissions::AccessGroup)
        assert @user.group.invisible?
        @user.group.level.must_equal Permissions::UserLevel::None
      end

      # the following actually works on the associated silent group
      it "default to a user level of Permissions::UserLevel.minimum" do
        @user.level.must_equal Permissions::UserLevel.none
      end

      it "have a settable user level" do
        @user.update(:level => Permissions::UserLevel[:root])
        @user.reload.level.must_equal Permissions::UserLevel.root
      end

      it "have a list of groups it belongs to" do
        @user.memberships.must_equal [@user.group]
      end

      it "be able to login with right login/password combination" do
        key = Permissions::User.authenticate(@user.login, @user.password)
        key.user.id.must_equal @user.id
        key = Permissions::User.authenticate(@user.login, "wrong password")
        key.must_be_nil
      end

      it "have a last login date" do
        @user.last_login_at.must_be_nil
        key = Permissions::User.authenticate(@user.login, @user.password)
        @user.reload.last_login_at.to_i.must_equal @now.to_i
      end

      it "generate a new access key on successful login" do
        @user.access_keys.must_be_empty
        key = Permissions::User.authenticate(@user.login, @user.password)
        @user.reload.access_keys.length.must_equal 1
        @user.access_keys.first.created_at.to_i.must_equal @now.to_i
        @user.access_keys.first.last_access_at.to_i.must_equal @now.to_i
      end

      it "have a list of access keys" do
        @user.access_keys.must_be_instance_of(Array)
      end

      it "be blockable" do
        @user.update(:disabled => true)
        key = Permissions::User.authenticate(@user.login, @user.password)
        key.must_be_nil
      end

      it "be able to belong to more than one group" do
        group1 = Permissions::AccessGroup.create(:name => "Group 1")
        group2 = Permissions::AccessGroup.create(:name => "Group 2")
        @user.add_group(group1)
        @user.add_group(group2)
        @user.groups.length.must_equal 2
        group1.members.must_equal [@user]
        group2.members.must_equal [@user]
      end

      it "return the right user level for a piece of content" do
        page = Page.create
        @user.update(:level => Permissions::UserLevel.admin)
        @user.access_selector.must_equal "*"
        @user.level_for(page).must_equal Permissions::UserLevel.admin
      end

      it "return the highest access level when multiple exist" do
        page = Page.create
        @user.update(:level => Permissions::UserLevel.none)
        group1 = Permissions::AccessGroup.create(:name => "Group 1", :level => Permissions::UserLevel.admin)
        group2 = Permissions::AccessGroup.create(:name => "Group 1", :level => Permissions::UserLevel.editor)
        group1.add_member(@user)
        group2.add_member(@user)
        @user.level_for(page).must_equal Permissions::UserLevel.admin
      end

      it "have a test for developer status" do
        @user.update(:level => Permissions::UserLevel.editor)
        refute @user.developer?
        @user.update(:level => Permissions::UserLevel.designer)
        assert @user.developer?
      end

      it "be testable for ability to publish depending on their user level" do
        @user.update(:level => Permissions::UserLevel.editor)
        refute @user.can_publish?
        @user.update(:level => Permissions::UserLevel.designer)
        assert @user.can_publish?
      end

      it "be testable for admin privileges" do
        @user.update(:level => Permissions::UserLevel.none)
        refute @user.admin?
        @user.update(:level => Permissions::UserLevel.editor)
        refute @user.admin?
        @user.update(:level => Permissions::UserLevel.designer)
        refute @user.admin?
        @user.update(:level => Permissions::UserLevel.admin)
        assert @user.admin?
        @user.update(:level => Permissions::UserLevel.root)
        assert @user.admin?
      end

      it "serialise to JSON" do
        @user.export.must_equal({
          :name => "A Person",
          :email => "person@example.org",
          :login => "person",
          :can_publish => false,
          :admin => false,
          :developer => false
        })
      end
    end
  end

  describe "access keys" do
    before do
      @now = Time.now
      Time.stubs(:now).returns(@now)
      @valid = {
        :name => "A Person",
        :email => "person@example.org",
        :login => "person",
        :password => "xxxxxxxx"
      }
    end

    after do
    end

    it "have a generated key_id" do
      key1 = Permissions::AccessKey.create
      key1.key_id.length.must_equal 44
      key2 = Permissions::AccessKey.create
      key2.key_id.length.must_equal 44
      key1.key_id.wont_equal key2.key_id
    end

    it "allow authentication of a user" do
      key1 = Permissions::AccessKey.create
      key2 = Permissions::AccessKey.authenticate(key1.key_id)
      key1.id.must_equal key2.id
    end

    it "update timestamps when authenticated" do
      user = Permissions::User.create(@valid)
      key1 = Permissions::AccessKey.create(:user_id => user.id)
      Time.stubs(:now).returns(@now + 1000)
      key2 = Permissions::AccessKey.create(:user_id => user.id)
      key3 = Permissions::AccessKey.authenticate(key2.key_id)
      key2.id.must_equal key3.id
      key2.reload.last_access_at.to_i.must_equal (@now+1000).to_i
      key2.user.last_access_at.to_i.must_equal (@now+1000).to_i
    end

    it "be guaranteed unique" do
      Permissions.stubs(:random_string).returns("xxxx")
      key1 = Permissions::AccessKey.create()
      lambda { Permissions::AccessKey.create() }.must_raise(Sequel::DatabaseError)
    end

    it "have a creation date" do
      key1 = Permissions::AccessKey.create
      key1.created_at.to_i.must_equal @now.to_i
    end

    it "retrieve their associated user" do
      user = Permissions::User.create(@valid)
      key1 = Permissions::AccessKey.create(:user_id => user.id)
      key1.reload.user.must_equal user
    end

    it "be disabled when user blocked" do
      user = Permissions::User.create(@valid)
      key1 = Permissions::AccessKey.create(:user_id => user.id)
      user.update(:disabled => true)
      key3 = Permissions::AccessKey.authenticate(key1.key_id)
      key3.must_be_nil
    end

    describe "csrf tokens" do
      before do
        user = Permissions::User.create(@valid)
        @key1 = Permissions::AccessKey.create(:user_id => user.id)
        @key2 = Permissions::AccessKey.create(:user_id => user.id)
      end

      it "be validatable" do
        token = @key1.generate_csrf_token
        assert @key1.csrf_token_valid?(token)
      end

      it "only be valid for the same token" do
        token = @key1.generate_csrf_token
        refute @key2.csrf_token_valid?(token)
      end

      it "recognises nil tokens as invalid" do
        refute @key2.csrf_token_valid?(nil)
      end
    end
  end



  describe "Groups" do
    before do
      @valid_group = { :name => "Some People" }
    end

    it "always have a name" do
      group = Permissions::AccessGroup.new(@valid_group.merge(:name => ""))
      refute group.valid?
      group.errors[:name].wont_be_empty
    end

    it "default to a user level of :none" do
      group = Permissions::AccessGroup.create(@valid_group)
      group.reload
      group.level.must_equal Permissions::UserLevel::None
    end

    # disabling a user and blocking a group are different
    # if you disable a user you disable their login
    # if you block a group they belong to you remove the permissions
    # granted by that group but you aren't stopping them from logging in
    it "be blockable" do
      group = Permissions::AccessGroup.create(@valid_group.merge(:level => Permissions::UserLevel.admin))
      group.level.must_equal Permissions::UserLevel.admin
      group.update(:disabled => true)
      group.level.must_equal Permissions::UserLevel.none
    end

    it "default to applying to the whole site" do
      group = Permissions::AccessGroup.create(@valid_group)
      group.access_selector.must_equal "*"
    end

    it "return the right user level for a piece of content" do
      group = Permissions::AccessGroup.create(@valid_group)
      page = Page.create
      group.update(:level => Permissions::UserLevel.admin)
      group.access_selector.must_equal "*"
      group.level_for(page).must_equal Permissions::UserLevel.admin
    end
  end

  describe "Guards" do
    before do
      Permissions::User.delete
      @visitor = Permissions::User.create(:email => "visitor@example.com", :login => "visitor", :name => "visitor", :password => "visitorpass")
      @editor = Permissions::User.create(:email => "editor@example.com", :login => "editor", :name => "editor", :password => "editorpass")
      @admin = Permissions::User.create(:email => "admin@example.com", :login => "admin", :name => "admin", :password => "adminpass")
      @root = Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass")
      @editor.update(:level => Permissions::UserLevel.editor)
      @admin.update(:level => Permissions::UserLevel.admin)
      @root.update(:level => Permissions::UserLevel.root)

      class ::C < Piece; end
      class ::D < Piece; end

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

      @i = C.new
    end

    after do
      Object.send(:remove_const, :C) rescue nil
      Object.send(:remove_const, :D) rescue nil
    end

    it "protect field reads" do
      # without user (e.g. terminal/console access) everything is always
      # possible
      assert @i.field_readable?(nil, :editor_level)
      assert @i.field_readable?(nil, :admin_level)
      assert @i.field_readable?(nil, :root_level)
      assert @i.field_readable?(nil, :mixed_level)
      assert @i.field_readable?(nil, :default_level)

      refute @i.field_readable?(@visitor, :editor_level)
      refute @i.field_readable?(@visitor, :admin_level)
      refute @i.field_readable?(@visitor, :root_level)
      refute @i.field_readable?(@visitor, :mixed_level)
      assert @i.field_readable?(@visitor, :default_level)

      assert @i.field_readable?(@editor, :editor_level)
      refute @i.field_readable?(@editor, :admin_level)
      refute @i.field_readable?(@editor, :root_level)
      assert @i.field_readable?(@editor, :mixed_level)
      assert @i.field_readable?(@editor, :default_level)

      assert @i.field_readable?(@admin, :editor_level)
      assert @i.field_readable?(@admin, :admin_level)
      refute @i.field_readable?(@admin, :root_level)
      assert @i.field_readable?(@admin, :mixed_level)
      assert @i.field_readable?(@admin, :default_level)

      assert @i.field_readable?(@root, :editor_level)
      assert @i.field_readable?(@root, :admin_level)
      assert @i.field_readable?(@root, :root_level)
      assert @i.field_readable?(@root, :mixed_level)
      assert @i.field_readable?(@root, :default_level)
    end

    it "protect field writes" do
      # without user (e.g. terminal/console access) everything is always
      # possible
      assert @i.field_writable?(nil, :editor_level)
      assert @i.field_writable?(nil, :admin_level)
      assert @i.field_writable?(nil, :root_level)
      assert @i.field_writable?(nil, :mixed_level)
      assert @i.field_writable?(nil, :default_level)

      refute @i.field_writable?(@visitor, :editor_level)
      refute @i.field_writable?(@visitor, :admin_level)
      refute @i.field_writable?(@visitor, :root_level)
      refute @i.field_writable?(@visitor, :mixed_level)
      refute @i.field_writable?(@visitor, :default_level)

      assert @i.field_writable?(@editor, :editor_level)
      refute @i.field_writable?(@editor, :admin_level)
      refute @i.field_writable?(@editor, :root_level)
      refute @i.field_writable?(@editor, :mixed_level)
      assert @i.field_writable?(@editor, :default_level)

      assert @i.field_writable?(@admin, :editor_level)
      assert @i.field_writable?(@admin, :admin_level)
      refute @i.field_writable?(@admin, :root_level)
      refute @i.field_writable?(@admin, :mixed_level)
      assert @i.field_writable?(@admin, :default_level)

      assert @i.field_writable?(@root, :editor_level)
      assert @i.field_writable?(@root, :admin_level)
      assert @i.field_writable?(@root, :root_level)
      assert @i.field_writable?(@root, :mixed_level)
      assert @i.field_writable?(@root, :default_level)
    end

    it "protect box reads" do
      assert @i.box_readable?(nil, :editor_level)
      assert @i.box_readable?(nil, :admin_level)
      assert @i.box_readable?(nil, :root_level)
      assert @i.box_readable?(nil, :mixed_level)
      assert @i.box_readable?(nil, :default_level)

      refute @i.box_readable?(@visitor, :editor_level)
      refute @i.box_readable?(@visitor, :admin_level)
      refute @i.box_readable?(@visitor, :root_level)
      refute @i.box_readable?(@visitor, :mixed_level)
      assert @i.box_readable?(@visitor, :default_level)

      assert @i.box_readable?(@editor, :editor_level)
      refute @i.box_readable?(@editor, :admin_level)
      refute @i.box_readable?(@editor, :root_level)
      assert @i.box_readable?(@editor, :mixed_level)
      assert @i.box_readable?(@editor, :default_level)

      assert @i.box_readable?(@admin, :editor_level)
      assert @i.box_readable?(@admin, :admin_level)
      refute @i.box_readable?(@admin, :root_level)
      assert @i.box_readable?(@admin, :mixed_level)
      assert @i.box_readable?(@admin, :default_level)

      assert @i.box_readable?(@root, :editor_level)
      assert @i.box_readable?(@root, :admin_level)
      assert @i.box_readable?(@root, :root_level)
      assert @i.box_readable?(@root, :mixed_level)
      assert @i.box_readable?(@root, :default_level)
    end
    it "protect box writes" do
      assert @i.box_writable?(nil, :editor_level)
      assert @i.box_writable?(nil, :admin_level)
      assert @i.box_writable?(nil, :root_level)
      assert @i.box_writable?(nil, :mixed_level)
      assert @i.box_writable?(nil, :default_level)

      refute @i.box_writable?(@visitor, :editor_level)
      refute @i.box_writable?(@visitor, :admin_level)
      refute @i.box_writable?(@visitor, :root_level)
      refute @i.box_writable?(@visitor, :mixed_level)
      refute @i.box_writable?(@visitor, :default_level)

      assert @i.box_writable?(@editor, :editor_level)
      refute @i.box_writable?(@editor, :admin_level)
      refute @i.box_writable?(@editor, :root_level)
      refute @i.box_writable?(@editor, :mixed_level)
      assert @i.box_writable?(@editor, :default_level)

      assert @i.box_writable?(@admin, :editor_level)
      assert @i.box_writable?(@admin, :admin_level)
      refute @i.box_writable?(@admin, :root_level)
      refute @i.box_writable?(@admin, :mixed_level)
      assert @i.box_writable?(@admin, :default_level)


      assert @i.box_writable?(@root, :editor_level)
      assert @i.box_writable?(@root, :admin_level)
      assert @i.box_writable?(@root, :root_level)
      assert @i.box_writable?(@root, :mixed_level)
      assert @i.box_writable?(@root, :default_level)
    end

    it "serialise only things in class viewable by the current user" do
      expected = [
        ["editor_level", true],
        ["admin_level", true],
        ["root_level", true],
        ["mixed_level", true],
        ["default_level", true]
      ]
      C.export[:fields].map { |f| [f[:name], f[:writable]] }.must_equal expected
      C.export[:boxes].map { |f| [f[:name], f[:writable]] }.must_equal expected
      C.export[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.must_equal [
        ["editor_level", expected],
        ["admin_level", expected],
        ["root_level", expected],
        ["mixed_level", expected],
        ["default_level", expected]
      ]

      # Permissions.with_user(@root) do
        C.export(@root)[:fields].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@root)[:boxes].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@root)[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.must_equal [
          ["editor_level", expected],
          ["admin_level", expected],
          ["root_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      # end

      # Permissions.with_user(@visitor) do
        expected = [
          ["default_level", false]
        ]
        C.export(@visitor)[:fields].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@visitor)[:boxes].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@visitor)[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.must_equal [
          ["default_level", expected ]
        ]
      # end

      # Permissions.with_user(@editor) do
        expected = [
          ["editor_level", true],
          ["mixed_level", false],
          ["default_level", true]
        ]
        C.export(@editor)[:fields].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@editor)[:boxes].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@editor)[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.must_equal [
          ["editor_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      # end

      # Permissions.with_user(@admin) do
        expected = [
          ["editor_level", true],
          ["admin_level", true],
          ["mixed_level", false],
          ["default_level", true]
        ]
        C.export(@admin)[:fields].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@admin)[:boxes].map { |f| [f[:name], f[:writable]] }.must_equal expected
        C.export(@admin)[:boxes].map { |b| [b[:name], b[:fields].map {|f| [f[:name], f[:writable]]}] }.must_equal [
          ["editor_level", expected],
          ["admin_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      # end
    end

    it "only list allowed types addable by the user" do
      allowed_type_names = Proc.new do |a|
        a[:type]
      end

      expected = [
        ["editor_level", ["D", "C"]],
        ["admin_level", ["C"]],
        ["root_level", ["C"]],
        ["mixed_level", ["C"]],
        ["default_level", ["C"]]
      ]
      C.export[:boxes].map { |b| [b[:name], b[:allowed_types].map(&allowed_type_names)] }.must_equal expected

      # Permissions.with_user(@root) do
        C.export(@root)[:boxes].map { |b| [b[:name], b[:allowed_types].map(&allowed_type_names)] }.must_equal expected
      # end
      # Permissions.with_user(@visitor) do
        expected = [
          ["default_level", []]
        ]
        C.export(@visitor)[:boxes].map { |b| [b[:name], b[:allowed_types].map(&allowed_type_names)] }.must_equal expected
      # end
      # Permissions.with_user(@editor) do
        expected = [
          ["editor_level", ["D"]],
          ["mixed_level", []],
          ["default_level", ["C"]]
        ]
        C.export(@editor)[:boxes].map { |b| [b[:name], b[:allowed_types].map(&allowed_type_names)] }.must_equal expected
      # end
      # Permissions.with_user(@admin) do
        expected = [
          ["editor_level", ["D", "C"]],
          ["admin_level", ["C"]],
          ["mixed_level", []],
          ["default_level", ["C"]]
        ]
        C.export(@admin)[:boxes].map { |b| [b[:name], b[:allowed_types].map(&allowed_type_names)] }.must_equal expected
      # end
    end

    it "serialise only things in instance viewable by the current user" do
      expected = [
        "editor_level",
        "admin_level",
        "root_level",
        "mixed_level",
        "default_level"
      ]
      @i.export[:boxes].map { |f| f[:name] }.must_equal expected
      @i.export[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.must_equal [
        ["editor_level", expected],
        ["admin_level", expected],
        ["root_level", expected],
        ["mixed_level", expected],
        ["default_level", expected]
      ]
      # Permissions.with_user(@root) do
        @i.export(@root)[:boxes].map { |f| f[:name] }.must_equal expected
        @i.export(@root)[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.must_equal [
          ["editor_level", expected],
          ["admin_level", expected],
          ["root_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      # end

      # Permissions.with_user(@visitor) do
        @i.export(@visitor)[:boxes].map { |f| f[:name] }.must_equal [
          "default_level"
        ]
        @i.export(@visitor)[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.must_equal [
          ["default_level", ["default_level"]]
        ]
      # end

      # Permissions.with_user(@editor) do
        expected = [
          "editor_level",
          "mixed_level",
          "default_level"
        ]
        @i.export(@editor)[:boxes].map { |f| f[:name] }.must_equal expected
        @i.export(@editor)[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.must_equal [
          ["editor_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      # end

      # Permissions.with_user(@admin) do
        expected = [
          "editor_level",
          "admin_level",
          "mixed_level",
          "default_level"
        ]
        @i.export(@admin)[:boxes].map { |f| f[:name] }.must_equal expected
        @i.export(@admin)[:boxes].map { |b| [b[:name], b[:fields].map {|f| f[:name]}] }.must_equal [
          ["editor_level", expected],
          ["admin_level", expected],
          ["mixed_level", expected],
          ["default_level", expected]
        ]
      # end

    end

    it "determine what fields are visible in the exoported schema" do
      schema = Site.schema.export(@editor)
      c_schema = schema["C"]
      c_schema[:fields].map { |f| f[:name] }.must_equal %w(editor_level mixed_level default_level)
      c_schema[:boxes].map { |b| b[:name] }.must_equal %w(editor_level mixed_level default_level)
    end
  end
end
