# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# set :environment, :test


class SchemaModificationTest < MiniTest::Spec
  include ::Rack::Test::Methods

  def self.startup
  end

  def self.site_root
    @site_root
  end

  def setup
    Spontaneous::Loader::Reloader.reset!
    @site_root = Dir.mktmpdir
    app_root = File.expand_path('../../fixtures/schema_modification', __FILE__)
    FileUtils.cp_r(app_root, @site_root)
    @site_root += "/schema_modification"

    @site = setup_site(@site_root)
    S::Content.delete
    Spontaneous::Permissions::User.delete

    @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass", :password_confirmation => "rootpass")
    @user.update(:level => Spontaneous::Permissions.root)
    @user.save
    @key = "c5AMX3r5kMHX2z9a5ExLKjAmCcnT6PFf22YQxzb4Codj"
    @key.stubs(:user).returns(@user)
    @key.stubs(:key_id).returns(@key)
    @user.stubs(:access_keys).returns([@key])

    Spontaneous::Permissions::User.stubs(:[]).with(:login => 'root').returns(@user)
    Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(@key).returns(@key)
    Spontaneous::Permissions::AccessKey.stubs(:valid?).with(@key, @user).returns(true)
    config = S.database.opts.dup.delete_if { |k, v| ![:user, :password, :host, :database, :adapter].include?(k) }

    config = { @site.environment => config }


    File.open(@site_root / "config/database.yml", 'w') do |f|
      f.write(config.to_yaml)
    end

    @site.initialize!

    S.schema.validate!
    S.schema.write_schema
    S.schema.schema_loader_class = S::Schema::PersistentMap

    @homepage = ::Page.create(:title => "Home", :uid => "home")
    @homepage.reload
      S::Rack::Back::EditingInterface.use Spontaneous::Rack::Reloader
        # Spontaneous::Loader.stubs(:reload!)
  end


  def teardown
    teardown_site
  end

  def app
    Spontaneous::Rack::Back.application
  end

  def auth_post(path, params={})
    post(path, params.merge("__key" => @key))
  end

  def auth_get(path, params={})
    get(path, params.merge("__key" => @key))
  end

  context "Box renaming" do
    setup do
    end

    should "work" do
      box_uid = ::Page.boxes.things.schema_id
      action = nil
      auth_get "/@spontaneous"
      assert last_response.ok?

      File.open(@site.root / "schema/page.rb", 'w') { |f|
        f.write(<<-RB)
          class Page < Spontaneous::Page
            field :title
            box :renamed, :type => :CustomBox do
            end
          end
        RB
      }
      S.schema.reset!
      Spontaneous::Loader::Reloader.reload!

      lambda { S.schema.validate! }.must_raise(Spontaneous::SchemaModificationError)

      begin
        S.schema.validate!
      rescue => e
        action = e.modification.actions.detect { |a| a.action == :rename }
      end

      # keep using this middleware to avoid problems with the cooldown setting
      S::Rack::Back::EditingInterface.use Spontaneous::Rack::Reloader
      auth_get "/@spontaneous/types"
      last_response.status.should == 412

      # keep using this middleware to avoid problems with the cooldown setting
      S::Rack::Back::EditingInterface.use Spontaneous::Rack::Reloader
      auth_post "/@spontaneous/schema/rename", {:origin => "/@spontaneous", :uid => action.source.to_s, :ref => action.dest.schema_name}

      # keep using this middleware to avoid problems with the cooldown setting
      S::Rack::Back::EditingInterface.use Spontaneous::Rack::Reloader
      auth_get "/@spontaneous"
      assert last_response.ok?
      ::Page.boxes.renamed.schema_id.should == box_uid
    end
  end
end
