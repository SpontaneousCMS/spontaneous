# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# set :environment, :test


describe "UserAdmin" do
  include RackTestMethods

  start do
    S::Permissions::User.delete
    site_root = Dir.mktmpdir
    app_root = File.expand_path('../../fixtures/user_manager', __FILE__)
    FileUtils.cp_r(app_root + "/", site_root)
    site_root += "/user_manager"
    let(:site_root) { site_root }
  end

  finish do
    teardown_site(true)
  end

  def app
    Spontaneous::Rack::Back.application(@site)
  end

  def api_key
    @key
  end

  before do
    @site = setup_site(site_root)
    Spot::Permissions::UserLevel.reset!
    Spot::Permissions::UserLevel.init!
    @editor_user = create_user("editor", S::Permissions[:editor])
    @admin_user  = create_user("admin", S::Permissions[:admin])
    @root_user   = create_user("root", S::Permissions[:root])

    assert @editor_user.level == S::Permissions[:editor]
    assert @admin_user.level  == S::Permissions[:admin]
    assert @root_user.level   == S::Permissions[:root]
  end

  after do
    teardown_site(false)
    S::Permissions::User.delete
  end

  def create_user(name, level)
    user = S::Permissions::User.create({
      :name => "#{name.capitalize}",
      :email => "#{name}@example.org",
      :login => name,
      :password => "#{name}_password"
    })
    user.update(:level => level)
    user
  end

  describe "Access to User admin" do
    it "be denied to unauthorised requests" do
      get "/@spontaneous/users"
      assert last_response.status == 401, "Expected 401 but got #{ last_response.status }"
    end

    it "be denied to users without the admin flag" do
      login_user(@editor_user)
      auth_get "/@spontaneous/users"
      assert last_response.status == 403, "Expected 403 but got #{ last_response.status }"
    end

    it "be granted to users with the admin flag" do
      login_user(@admin_user)
      auth_get "/@spontaneous/users"
      assert last_response.status == 200, "Expected 200 but got #{ last_response.status }"
    end

    it "be granted to root users" do
      login_user(@root_user)
      auth_get "/@spontaneous/users"
      assert last_response.status == 200, "Expected 200 but got #{ last_response.status }"
    end
  end

  describe "User application" do
    before do
      login_user(@admin_user)
    end

    it "return serialised list of current users" do
      auth_get "/@spontaneous/users"
      result = S::JSON.parse last_response.body
      result.must_equal S::Permissions::User.export(@user)
    end

    it "allow user details to be updated" do
      auth_put "/@spontaneous/users/#{@editor_user.id}", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org" }
      assert last_response.ok?, "Recieved a #{ last_response.status } instead of a 200"
      @editor_user.reload.login.must_equal "robert"
    end

    it "allow a users level to be changed" do
      auth_put "/@spontaneous/users/#{@editor_user.id}", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org", "user[level]" => "admin" }
      assert last_response.ok?, "Recieved a #{ last_response.status } instead of a 200"
      @editor_user.reload.level.must_equal @admin_user.level
    end

    it "reject updates that change the level above the current user's" do
      level = @editor_user.level
      auth_put "/@spontaneous/users/#{@editor_user.id}", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org", "user[level]" => "root" }
      assert last_response.status == 403, "Recieved a #{ last_response.status } instead of a 403"
      @editor_user.reload.level.must_equal level
    end

    it "reject an update with a conflicting login" do
      auth_put "/@spontaneous/users/#{@editor_user.id}", {  "user[name]" => "Robert Something", "user[login]" => "admin", "user[email]" => "robert@example.org" }
      assert last_response.status == 422, "Recieved a #{ last_response.status } instead of a 422"
      @editor_user.reload.login.must_equal "editor"
      result = S::JSON.parse last_response.body
      result.must_be_instance_of Hash
      result[:login].wont_be_nil
    end

    it "reject an update with an invalid email" do
      email = @editor_user.email
      auth_put "/@spontaneous/users/#{@editor_user.id}", {  "user[name]" => "Robert Something", "user[login]" => "editor", "user[email]" => "robert" }
      assert last_response.status == 422, "Recieved a #{ last_response.status } instead of a 422"
      @editor_user.reload.email.must_equal email
      result = S::JSON.parse last_response.body
      result.must_be_instance_of Hash
      result[:email].wont_be_nil
    end

    it "allow updating of the user's password" do
      new_pass = "123467890"
      auth_put "/@spontaneous/users/password/#{@editor_user.id}", {  "password" => new_pass }
      assert last_response.ok?, "Recieved status #{ last_response.status} instead of 200"
      key = Spontaneous::Permissions::User.authenticate(@editor_user.login, new_pass, "127.0.0.1")
      key.wont_be_nil
    end

    it "reject & return error for invalid passwords" do
      new_pass = "1234"
      auth_put "/@spontaneous/users/password/#{@editor_user.id}", {  "password" => new_pass }
      assert last_response.status == 422, "Recieved a #{ last_response.status } instead of a 422"
      key = Spontaneous::Permissions::User.authenticate(@editor_user.login, new_pass, "127.0.0.1")
      key.must_be_nil
      result = S::JSON.parse last_response.body
      result.must_be_instance_of Hash
      result[:password].wont_be_nil
    end

    it "not allow changing details of users with higher level" do
      auth_put "/@spontaneous/users/#{@root_user.id}", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org" }
      assert last_response.status == 403, "Recieved a #{ last_response.status } instead of a 403"
      @root_user.reload.login.must_equal "root"
    end

    # it "allow admins to reset their password"
    it "enable a force-logout of a user by deleting their keys" do
      3.times do |n|
        @editor_user.generate_access_key("203.99.33.#{n}")
      end
      @editor_user.access_keys.length.must_equal 3
      auth_del "/@spontaneous/users/keys/#{@editor_user.id}"
      assert last_response.ok?, "Recieved status #{ last_response.status} instead of 200"
      @editor_user.reload.access_keys.length.must_equal 0
    end

    it "not allow logging out of user with higher level" do
      3.times do |n|
        @root_user.generate_access_key("203.99.33.#{n}")
      end
      @root_user.access_keys.length.must_equal 3
      auth_del "/@spontaneous/users/keys/#{@root_user.id}"
      assert last_response.status == 403, "Recieved a #{ last_response.status } instead of a 403"
      @root_user.reload.access_keys.length.must_equal 3
    end

    it "allow you to disable a user" do
      refute @editor_user.disabled?
      auth_put "/@spontaneous/users/disable/#{@editor_user.id}"
      assert last_response.ok?
      assert @editor_user.reload.disabled?
    end

    it "allow you to re-enable a user" do
      refute @editor_user.disabled?
      @editor_user.disable!
      auth_put "/@spontaneous/users/enable/#{@editor_user.id}"
      assert last_response.ok?
      refute @editor_user.reload.disabled?
    end

    it "not allow you to disable a user with a higher user level" do
      refute @root_user.disabled?
      auth_put "/@spontaneous/users/disable/#{@root_user.id}"
      assert last_response.status == 403, "Recieved a #{ last_response.status } instead of a 403"
      refute @root_user.reload.disabled?
    end

    it "allow for the creation of new users" do
      auth_post "/@spontaneous/users", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org", "user[password]" => "robertpass", "user[level]" => "admin" }
      assert last_response.ok?, "Recieved status #{ last_response.status} instead of 200"
      user = S::Permissions::User[:login => "robert"]
      user.must_be_instance_of S::Permissions::User
      user.name.must_equal "Robert Something"
      user.email.must_equal "robert@example.org"
      user.level.must_equal Spontaneous::Permissions[:admin]
      key = Spontaneous::Permissions::User.authenticate("robert", "robertpass", "127.0.0.1")
      key.must_be_instance_of S::Permissions::AccessKey
      key.user.id.must_equal user.id
    end

    it "return user info on account creation" do
      auth_post "/@spontaneous/users", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org", "user[password]" => "robertpass", "user[level]" => "admin" }
      assert last_response.ok?, "Recieved status #{ last_response.status} instead of 200"
      result = S::JSON.parse last_response.body
      result[:id].wont_be_nil
      user = S::Permissions::User[result[:id]]
      result.must_equal S::Permissions::User.export_user(user)
    end

    it "not allow creation of users with higher level" do
      users = S::Permissions::User.count
      auth_post "/@spontaneous/users", {  "user[name]" => "Robert Something", "user[login]" => "robert", "user[email]" => "robert@example.org", "user[password]" => "robertpass", "user[level]" => "root" }
      assert last_response.status == 403, "Recieved a #{ last_response.status } instead of a 403"
      S::Permissions::User.count.must_equal users
    end

    it "return an error if passed invalid user attributes" do
      users = S::Permissions::User.count
      auth_post "/@spontaneous/users", {  "user[name]" => "Robert Something", "user[login]" => "admin", "user[email]" => "robert", "user[password]" => "pass", "user[level]" => "editor" }
      assert last_response.status == 422, "Recieved a #{ last_response.status } instead of a 422"
      S::Permissions::User.count.must_equal users
    end

    it "allow us to delete a user" do
      auth_del "/@spontaneous/users/#{@editor_user.id}"
      assert last_response.status == 200, "Recieved a #{ last_response.status } instead of a 200"
      user = Spontaneous::Permissions::User[:login => @editor_user.login]
      user.must_be_nil
    end

    it "not allow us to delete a user with a higher user level" do
      auth_del "/@spontaneous/users/#{@root_user.id}"
      assert last_response.status == 403, "Recieved a #{ last_response.status } instead of a 403"
      user = Spontaneous::Permissions::User[:login => @root_user.login]
      user.wont_be_nil
    end
  end
end
