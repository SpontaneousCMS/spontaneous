

require File.expand_path('../../test_helper', __FILE__)


describe "Back" do
  include RackTestMethods


  start do
    root = Dir.mktmpdir
    app_root = File.expand_path('../../fixtures/back', __FILE__)
    FileUtils.cp_r(app_root, root)
    root += "/back"
    FileUtils.mkdir_p(root / "cache")
    FileUtils.cp_r(File.join(File.dirname(__FILE__), "../fixtures/media"), root / "cache")
    Spontaneous::Permissions::UserLevel.reset!
    @level_file = root / "config/user_levels.yml"
    Spontaneous::Permissions::UserLevel.stubs(:level_file).returns(@level_file)
    let(:site_root) { root }

    Spontaneous::Permissions::User.delete
    # annoying to have to do this, but there you go
    user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root name", :password => "rootpass")
    user.update(:level => Spontaneous::Permissions[:editor])
    user.save.reload
    key = user.generate_access_key("127.0.0.1")

    Spontaneous::Permissions::User.stubs(:[]).with(:login => 'root').returns(user)
    Spontaneous::Permissions::User.stubs(:[]).with(user.id).returns(user)
    Spontaneous::Permissions::AccessKey.stubs(:authenticate).with(key.key_id).returns(key)

    let(:user) { user }
    let(:key) { key }

    site = setup_site(root, true)

    site.config.tap do |c|
      c.reload_classes = false
      c.auto_login = 'root'
      c.default_charset = 'utf-8'
      c.background_mode = :immediate
      c.site_domain = 'example.org'
      c.site_id = 'example_org'
    end

    let(:site) { site }

    Content.delete

    Page.field :title

    class ::Project < Page; end
    class ::Image < Piece
      field :image, :image
    end

    class ::Job < Piece
      field :title
      field :image, :image
      field :client, :select, :options => [["a", "Value A"], ["b", "Value B"]]

      box :images do
        field :title
        field :image
        allow Image
      end
    end

    class ::LinkedJob < Piece
      alias_of proc { |owner, box| box.contents }
    end

    class ::HomePage < Page
      field :introduction, :richtext
      box :projects do
        allow Project
      end
      box :in_progress do
        allow Job
        allow Image
      end

      box :featured_jobs do
        allow LinkedJob
      end
    end

    class ::AdminAccess < Page
      field :title
      field :private, :user_level => :root
    end

    home = HomePage.new(:title => "Home")
    project1 = Project.new(:title => "Project 1", :slug => "project1")
    project2 = Project.new(:title => "Project 2", :slug => "project2")
    project3 = Project.new(:title => "Project 3", :slug => "project3")
    home.projects << project1
    home.projects << project2
    home.projects << project3

    job1 = Job.new(:title => "Job 1", :image => "/i/job1.jpg")
    job2 = Job.new(:title => "Job 2", :image => "/i/job2.jpg")
    job3 = Job.new(:title => "Job 3", :image => "/i/job3.jpg")
    image1 = Image.new
    job1.images << image1
    home.in_progress << job1
    home.in_progress << job2
    home.in_progress << job3


    home.save

    let(:home_id) { home.id }
    let(:project1_id) { project1.id }
    let(:project2_id) { project2.id }
    let(:project3_id) { project3.id }
    let(:job1_id) { job1.id }
    let(:job2_id) { job2.id }
    let(:job3_id) { job3.id }
    let(:image1_id) { image1.id }
  end

  finish do
    [:Page, :Piece, :HomePage, :Job, :Project, :Image, :LinkedJob, :AdminAccess].each do |klass|
      Object.send(:remove_const, klass) rescue nil
    end
    Spontaneous::Permissions::User.delete
    Content.delete if defined?(Content)
    teardown_site(true)
  end

  def app
    @app ||= Spontaneous::Rack::Back.application(site)
  end

  let(:home) { Content[home_id] }
  let(:project1) { Content[project1_id] }
  let(:project2) { Content[project2_id] }
  let(:project3) { Content[project3_id] }
  let(:job1) { Content[job1_id] }
  let(:job2) { Content[job2_id] }
  let(:job3) { Content[job3_id] }
  let(:image1) { Content[image1_id] }

  before do
    @now = Time.now
    stub_time(@now)
    storage = site.default_storage
    site.stubs(:storage).with(anything).returns(storage)
  end


  # Used by the various auth_* methods
  def api_key
    key
  end

  it "retrieves /@spontaneous without a CSRF token" do
    get("/@spontaneous")
    assert last_response.ok?, "Index retrieval should succeed without CSRF tokens"
    assert_contains_csrf_token(key)
  end

  it "retrieves /@spontaneous/ without a CSRF token" do
    get("/@spontaneous/")
    assert last_response.ok?, "Index retrieval should succeed without CSRF tokens"
    assert_contains_csrf_token(key)
  end

  it "retrieves any page identified by an id without a CSRF token" do
    get("/@spontaneous/#{project1.id}/edit")
    assert last_response.ok?, "Index retrieval should succeed without CSRF tokens"
    assert_contains_csrf_token(key)
  end

  describe "/@spontaneous" do
    before do
      self.template_root = File.expand_path('../../fixtures/back/templates', __FILE__)
      @app_dir = File.expand_path("../../fixtures/application", __FILE__)
      assert File.exists?(@app_dir)
      Spontaneous.stubs(:application_dir).returns(@app_dir)
    end

    it "returns application page" do
      get '/@spontaneous/'
      assert last_response.ok?, "Should have returned 200 but got #{last_response.status}"
      last_response.body.must_match /<title>Spontaneous/
    end

    describe "/map" do
      it "return a site map for root by default" do
        auth_get '/@spontaneous/map'
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        assert_equal site.map.to_json, last_response.body
      end

      it "return a site map for any page id" do
        auth_get "/@spontaneous/map/#{home.id}"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        assert_equal site.map(home.id).to_json, last_response.body
      end

      it "return a site map for any url" do
        page = project1
        auth_get "/@spontaneous/map/path#{project1.path}"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        assert_equal site.map(project1.id).to_json, last_response.body
      end

      it "return 404 when asked for map of non-existant page" do
        id = '9999'
        ::Content.stubs(:[]).with(id).returns(nil)
        auth_get "/@spontaneous/map/#{id}"
        assert last_response.status == 404
      end

      it "return the correct Last-Modified header for the site map" do
        now = Time.at(Time.now.to_i + 10000)
        site.stubs(:modified_at).returns(now)
        auth_get '/@spontaneous/map'
        Time.httpdate(last_response.headers["Last-Modified"]).must_equal now
        auth_get "/@spontaneous/map/path#{project1.path}"
        Time.httpdate(last_response.headers["Last-Modified"]).must_equal now
      end

      it "reply with a 304 Not Modified if the site hasn't been updated since last request" do
        datestring = "Sat, 03 Mar 2012 00:49:44 GMT"
        now = Time.httpdate(datestring)
        site.stubs(:modified_at).returns(now)
        auth_get "/@spontaneous/map/#{home.id}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring}
        last_response.status.must_equal 304
        auth_get "/@spontaneous/map", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring}
        last_response.status.must_equal 304
        auth_get "/@spontaneous/map/path#{project1.path}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring}
        last_response.status.must_equal 304
      end

      it "return the map data if the site has been updated since last request" do
        datestring1 = "Sat, 03 Mar 2012 00:49:44 GMT"
        datestring2 = "Sat, 03 Mar 2012 01:49:44 GMT"
        now = Time.httpdate(datestring2)
        site.stubs(:modified_at).returns(now)
        auth_get "/@spontaneous/map/#{home.id}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring1}
        last_response.status.must_equal 200
        auth_get "/@spontaneous/map/path#{project1.path}", {}, {"HTTP_IF_MODIFIED_SINCE" => datestring1}
        last_response.status.must_equal 200
      end
    end

    describe "/field" do
      it "generates an error if there is a field version conflict" do
        field = job1.fields.title
        field.version = 3
        job1.save.reload
        field = job1.fields.title
        sid = field.schema_id.to_s
        params = { "fields" => {sid => "2"} }

        auth_post "/@spontaneous/field/conflicts/#{job1.id}", params
        assert last_response.status == 409, "Should have recieved a 409 conflict but instead received a #{last_response.status}"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        result = Spontaneous.deserialise_http(last_response.body)
        result.must_equal({
          sid.to_sym => [ field.version, field.value ]
        })
      end

      it "not generate an error if the pending version of the field matches" do
        field = job1.fields.title
        field.version = 2
        field.processed_values[:__pending__] = {:value => "something.gif", :version => 3 }
        job1.save_fields
        job1.reload
        field = job1.fields.title
        field.pending_version.must_equal 3
        sid = field.schema_id.to_s
        params = { "fields" => {sid => "3"} }

        auth_post "/@spontaneous/field/conflicts/#{job1.id}", params
        assert last_response.status == 200, "Should have recieved a 200 OK but instead received a #{last_response.status}"
      end


      it "generate an error if there is a field version conflict for boxes" do
        box = job1.images
        field = box.fields.title
        field.version = 3
        field.modified!
        job1.save.reload
        box = job1.images
        field = box.fields.title
        sid = field.schema_id.to_s
        params = { "fields" => {sid => "2"} }

        auth_post "/@spontaneous/field/conflicts/#{job1.id}/#{box.schema_id.to_s}", params
        assert last_response.status == 409, "Should have recieved a 409 conflict but instead received a #{last_response.status}"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        result = Spontaneous.deserialise_http(last_response.body)
        result.must_equal({
          sid.to_sym => [ 3, field.value ]
        })
      end

      it "be able to provide a dynamic value list" do
        job1.reload
        list = mock()
        options = [["a", "Value A"], ["b", "Value B"]]
        list.expects(:values).with(job1).returns(options)
        field = Job.field :client_dynamic, :select, :options => proc { |content| list.values(content) }
        auth_get "/@spontaneous/field/options/#{field.schema_id}/#{job1.id}"
        assert last_response.ok?,  "Expected status 200 but received #{last_response.status}"
        result = Spot::JSON.parse(last_response.body)
        result.must_equal options
      end

      it "be able to provide a dynamic value list for a box field" do
        job1.reload
        list = mock()
        options = [["a", "Value A"], ["b", "Value B"]]
        list.expects(:values).with(job1.images).returns(options)
        field = Job.boxes.images.instance_class.field :client, :select, :options => proc { |box| list.values(box) }
        auth_get "/@spontaneous/field/options/#{field.schema_id}/#{job1.id}/#{Job.boxes.images.schema_id}"
        assert last_response.ok?,  "Expected status 200 but received #{last_response.status}"
        result = Spot::JSON.parse(last_response.body)
        result.must_equal options
      end

    end

    describe "/site" do
      before do
        @root_class = site.home.class
      end

      it "return json for home page" do
        auth_get '/@spontaneous/site/home'
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        assert_equal S::JSON.encode(site.home.export), last_response.body
      end

      it "return the typelist as part of the site metadata" do
        auth_get "/@spontaneous/site"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        result = Spot::JSON.parse(last_response.body)
        result[:types].stringify_keys.must_equal site.schema.export(user)
      end

      it "apply the current user's permissions to the exported schema" do
        auth_get "/@spontaneous/site"
        assert last_response.ok?
        result = Spot::JSON.parse(last_response.body)
        result[:types][:'AdminAccess'][:fields].map { |f| f[:name] }.must_equal %w(title)
      end

      it "return info about the current user in the metadata" do
        auth_get "/@spontaneous/site"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        result[:user][:email].must_equal "root@example.com"
        result[:user][:login].must_equal "root"
        result[:user][:name].must_equal "root name"
        result[:user][:developer].must_equal false # although the login is root, the level is :editor
      end

      it "returns a list of site roots in the metadata" do
        hidden = Page.create slug: "hidden"
        auth_get "/@spontaneous/site"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        roots = result[:roots]
        roots.must_equal({
          :public => "example.org",
          :roots => { :"example.org"=>home.id, :"#hidden"=>hidden.id }
        })
      end

      it "return an empty list of service URLs by default" do
        auth_get "/@spontaneous/site"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        result[:services].must_equal []
      end

      it "return the configured list of service URLs in the metadata" do
        site.config.stubs(:services).returns([
          {:title => "Google Analytics", :url => "http://google.com/analytics"},
          {:title => "Facebook", :url => "http://facebook.com/spontaneous"}
        ])
        auth_get "/@spontaneous/site"
        assert last_response.ok?, "Should have recieved a 200 OK but got a #{ last_response.status }"
        result = Spot::JSON.parse(last_response.body)
        result[:services].must_equal site.config.services
      end
      it "provides a format value for date fields" do
        field = Job.field :date, :date, :format => "%Y %d %a"
        auth_get "/@spontaneous/site"
        schema = Spot::JSON.parse(last_response.body)
        field = schema[:types][:"Job"][:fields].detect { |f| f[:name] == "date" }
        field[:date_format].must_equal  "%Y %d %a"
      end

      it "provides values for a  static option list" do
        # static lists should be included in the field definitions
        # field = Job.field :client, :select, :options => [["a", "Value A"], ["b", "Value B"]]
        auth_get "/@spontaneous/site"

        schema = Spot::JSON.parse(last_response.body)
        field = schema[:types][:"Job"][:fields].detect { |f| f[:name] == "client" }
        field[:option_list].must_equal [["a", "Value A"], ["b", "Value B"]]
      end

      describe "new" do
        before do
          Content.delete
        end

        it "raises a 406 when downloading page details" do
          auth_get "/@spontaneous/map/path/"
          last_response.status.must_equal 406
        end

        it "creates a homepage of the specified type" do
          auth_post "/@spontaneous/site/home", 'type' => @root_class.schema_id
          assert last_response.ok?
          site.home.must_be_instance_of(@root_class)
          site.home.title.value.must_match /Home/
        end

        it "only creates one homepage" do
          auth_post "/@spontaneous/site/home", 'type' => @root_class.schema_id
          assert last_response.ok?
          Content.count.must_equal 1
          auth_post "/@spontaneous/site/home", 'type' => @root_class.schema_id
          assert last_response.status == 403
          Content.count.must_equal 1
        end
      end
    end

    describe "/content" do
      it "updates field values" do
        params = {
          "field[#{job1.fields.title.schema_id.to_s}]" => "Updated field_name_1"
        }
        auth_put "/@spontaneous/content/#{job1.id}", params
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        job = Content[job1.id]
        last_response.body.must_equal job.serialise_http(user)
        job.fields.title.value.must_equal  "Updated field_name_1"
      end

      it "updates page field values" do
        params = {
          "field[#{home.fields.title.schema_id.to_s}]" => "Updated title",
            "field[#{home.fields.introduction.schema_id.to_s}]" => "Updated intro"
        }
        auth_put "/@spontaneous/content/#{home.id}", params
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        reload = Content[home.id]
        last_response.body.must_equal reload.serialise_http(user)
        reload.fields.title.value.must_equal  "Updated title"
        reload.fields.introduction.value.must_equal  "<p>Updated intro</p>\n"
      end

      it "triggers replacement of default slug if title is first set" do
        project = Project.new
        home.projects << project
        home.save
        assert project.has_generated_slug?
        params = {
          "field[#{home.fields.title.schema_id.to_s}]" => "Updated title",
        }
        auth_put "/@spontaneous/content/#{project.id}", params
        project.reload
        project.slug.must_equal "updated-title"
        refute project.has_generated_slug?
      end

      it "updates box field values" do
        box = job1.images
        box.fields.title.to_s.wont_equal "Updated title"
        params = {
          "field[#{box.fields.title.schema_id.to_s}]" => "Updated title"
        }
        auth_put "/@spontaneous/content/#{job1.id}/#{box.schema_id.to_s}", params
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        job = Content[job1.id]
        job.images.title.value.must_equal "Updated title"
      end

      it "toggles visibility" do
        job1.reload.visible?.must_equal true
        auth_patch "/@spontaneous/content/#{job1.id}/toggle"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        Spot::JSON.parse(last_response.body).must_equal([{id: job1.id, hidden: true}, {id: image1.id, hidden: true}])
        job1.reload.visible?.must_equal false
        auth_patch "/@spontaneous/content/#{job1.id}/toggle"
        assert last_response.ok?, "Expected status 200 but recieved #{last_response.status}"
        job1.reload.visible?.must_equal true
        Spot::JSON.parse(last_response.body).must_equal([{id: job1.id, hidden: false}, {id: image1.id, hidden: false}])
      end

      it "returns the list of affected items when toggling visibility" do
        job1.reload.visible?.must_equal true
        job1_alias = LinkedJob.new(target: job1)
        home.featured_jobs << job1_alias
        job1_alias.save
        auth_patch "/@spontaneous/content/#{job1.id}/toggle"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        Spot::JSON.parse(last_response.body).must_equal([{id: job1.id, hidden: true}, {id: image1.id, hidden: true}, {id: job1_alias.id, hidden: true}])
        job1.reload.visible?.must_equal false
        job1_alias.reload.visible?.must_equal false
        auth_patch "/@spontaneous/content/#{job1.id}/toggle"
        assert last_response.ok?, "Expected status 200 but recieved #{last_response.status}"
        job1.reload.visible?.must_equal true
        Spot::JSON.parse(last_response.body).must_equal([{id: job1.id, hidden: false}, {id: image1.id, hidden: false}, {id: job1_alias.id, hidden: false}])
      end

      it "sets the position of pieces" do
        auth_patch "/@spontaneous/content/#{job2.id}/position/0"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.in_progress.contents.first.id.must_equal job2.id

        page = Content[home.id]
        page.in_progress.contents.first.id.must_equal job2.id
      end

      it "sets the position of pages" do

        auth_patch "/@spontaneous/content/#{project3.id}/position/0"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.projects.contents.first.id.must_equal project3.id

        page = Content[home.id]
        page.projects.contents.first.id.must_equal project3.id
      end

      it "records the currently logged in user" do
        page = home.in_progress.last
        auth_patch "/@spontaneous/content/#{page.id}/toggle"
        assert last_response.ok?, "Expected status 200 but received #{last_response.status}"
        page.reload
        page.pending_modifications(:visibility).first.user.must_equal user
      end

      it "allows addition of pages" do
        current_count = home.projects.length
        auth_post "/@spontaneous/content/#{home.id}/#{home.projects.schema_id.to_s}/#{Project.schema_id.to_s}"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        home.reload
        home.projects.length.must_equal current_count+1
        home.projects.first.must_be_instance_of(Project)
      end

      it "default to adding entries at the top" do
        current_count = home.in_progress.contents.length
        first_id = home.in_progress.contents.first.id
        home.in_progress.contents.first.class.name.wont_equal "Image"
        auth_post "/@spontaneous/content/#{home.id}/#{home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}"
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.in_progress.contents.length.must_equal current_count+1
        home.in_progress.contents.first.id.wont_equal first_id
        home.in_progress.contents.first.class.name.must_equal "Image"
        required_response = {
          :position => 0,
          :entry => home.in_progress.contents.first.export
        }
        Spot::JSON.parse(last_response.body).must_equal required_response
      end

      it "allows adding of entries at the bottom" do
        current_count = home.in_progress.contents.length
        last_id = home.in_progress.contents.last.id
        home.in_progress.contents.last.class.name.wont_equal "Image"
        auth_post "/@spontaneous/content/#{home.id}/#{home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}", :position => -1
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.in_progress.contents.length.must_equal current_count+1
        home.in_progress.contents.last.id.wont_equal last_id
        home.in_progress.contents.last.class.name.must_equal "Image"
        required_response = {
          :position => -1,
          :entry => home.in_progress.contents.last.export
        }
        Spot::JSON.parse(last_response.body).must_equal required_response
      end


      it "allows adding of new entries after an existing entry" do
        current_count = home.in_progress.contents.length
        box = home.in_progress
        existing = box[box.length - 1]
        auth_post "/@spontaneous/content/#{home.id}/#{home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}", after_id: existing.id
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        box = home.in_progress
        box.length.must_equal current_count+1
        box[box.length - 1].class.name.must_equal "Image"
        added = box[box.length - 1]
        required_response = {
          :position => box.length - 1,
          :entry => added.export
        }
        Spot::JSON.parse(last_response.body).must_equal required_response
      end

      it "creates entries with the owner set to the logged in user" do
        auth_post "/@spontaneous/content/#{home.id}/#{home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}", :position => 0
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        home.reload
        home.in_progress.first.created_by_id.must_equal user.id
        home.in_progress.first.created_by.must_equal user
      end

      it "allows the deletion of items" do
        target = home.in_progress.first
        auth_delete "/@spontaneous/content/#{target.id}"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        Content[target.id].must_be_nil
      end
    end

    describe "/file" do
      before do
        @src_file = Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/images/rose.jpg")).realpath.to_s
        @upload_id = 9723
        Spontaneous::Media.stubs(:upload_index).returns(23)
        @upload = ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg")
      end

      it "replace values of fields immediately when required" do
        image1.image.processed_value.must_equal ""
        auth_put("@spontaneous/file/#{image1.id}", "file" => @upload, "field" => image1.image.schema_id.to_s )
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        image = Content[image1.id]
        src = image.image.src
        src.must_match /^\/media(.+)\/rose\.jpg$/
        Spot::JSON.parse(last_response.body).must_equal image.image.export
        assert File.exist?(S::Media.to_filepath(src))
        get src
        assert last_response.ok?
      end

      it "replace values of box file fields" do
        job1.images.image.processed_value.must_equal ""
        auth_put("@spontaneous/file/#{job1.id}/#{job1.images.schema_id}",
                 "file" => @upload, "field" => job1.images.image.schema_id.to_s)
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        job = Content[job1.id]
        src = job.images.image.src
        src.must_match /^\/media(.+)\/rose\.jpg$/
        Spot::JSON.parse(last_response.body).must_equal job.images.image.export
        assert File.exist?(S::Media.to_filepath(src))
        get src
        assert last_response.ok?
      end

      it "be able to wrap pieces around files using default addable class" do
        box = job1.images
        current_count = box.contents.length
        first_id = box.contents.first.id.to_s
        auth_post "/@spontaneous/file/#{job1.id}/#{box.schema_id.to_s}", "file" => @upload
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        box = job1.reload.images
        first = box.contents.first
        box.contents.length.must_equal current_count+1
        first.image.src.must_match /^\/media(.+)\/#{File.basename(@src_file)}$/
        required_response = {
          :position => 0,
          :entry => first.export
        }
        Spot::JSON.parse(last_response.body).must_equal required_response
      end
    end

    describe "/shard" do
      before do
        Spontaneous.stubs(:reload!)
        @image = File.expand_path("../../fixtures/sharding/rose.jpg", __FILE__)
        # read the digest dynamically in case I change that image
        @image_digest = S::Media.digest(@image)
      end

      it "has the right setting for shard_dir" do
        shard_path = File.join(site.root / 'cache/tmp')
        Spontaneous.shard_path.must_equal shard_path
        Spontaneous.shard_path("abcdef0123").must_equal shard_path/ "ab/cd/abcdef0123"
      end

      it "knows when it already has a shard" do
        hash = '4d68c8f13459c0edb40504de5003ec2a6b74e613'
        FileUtils.touch(Spontaneous.shard_path(hash))
        FileUtils.expects(:touch).with(Spontaneous.shard_path(hash))
        auth_get "/@spontaneous/shard/#{hash}"
        last_response.status.must_equal 200
      end

      it "knows when it doesn't have a shard" do
        auth_get "/@spontaneous/shard/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        last_response.status.must_equal 404
      end

      it "receives a shard and puts it in the right place" do
        auth_post "@spontaneous/shard/#{@image_digest}", "file" => ::Rack::Test::UploadedFile.new(@image, "image/jpeg")
        assert last_response.ok?
        auth_get "/@spontaneous/shard/#{@image_digest}"
        last_response.status.must_equal 200
      end

      it "returns an error if the uploaded file has the wrong hash" do
        S::Media.expects(:digest).with(anything).returns("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
        auth_post "@spontaneous/shard/#{@image_digest}", "file" => ::Rack::Test::UploadedFile.new(@image, "image/jpeg")
        last_response.status.must_equal 409
      end

      it "reassembles multiple parts into a single file and attaches it to a content item" do
        parts = %w(xaa xab xac xad xae xaf xag)
        paths = parts.map { |part| File.expand_path("../../fixtures/sharding/#{part}", __FILE__) }
        hashes = paths.map { |path| S::Media.digest(path) }
        paths.each_with_index do |part, n|
          auth_post "/@spontaneous/shard/#{hashes[n]}", "file" => ::Rack::Test::UploadedFile.new(part, "application/octet-stream")
        end
        hashes.each do |hash|
          auth_get "/@spontaneous/shard/#{hash}"
          last_response.status.must_equal 200
        end
        image1.image.processed_value.must_equal ""
        dataset = mock()
        ::Content.stubs(:for_update).returns(dataset)
        dataset.stubs(:get).with(image1.id.to_s).returns(image1)
        dataset.stubs(:get).with(image1.id).returns(image1)
        auth_put "/@spontaneous/shard/#{image1.id}", "filename" => "rose.jpg",
        "shards" => hashes, "field" => image1.image.schema_id.to_s
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        image = Content[image1.id]
        src = image.image.src
        src.must_match %r{^(.+)/rose\.jpg$}
        Spot::JSON.parse(last_response.body).must_equal image.image.export
        assert File.exist?(S::Media.to_filepath(src))
      end

      it "wraps pieces around files using default addable class" do
        parts = %w(xaa xab xac xad xae xaf xag)
        paths = parts.map { |part| File.expand_path("../../fixtures/sharding/#{part}", __FILE__) }
        hashes = paths.map { |path| S::Media.digest(path) }
        paths.each_with_index do |part, n|
          auth_post "/@spontaneous/shard/#{hashes[n]}", "file" => ::Rack::Test::UploadedFile.new(part, "application/octet-stream")
        end
        hashes.each do |hash|
          auth_get "/@spontaneous/shard/#{hash}"
          last_response.status.must_equal 200
        end
        box = job1.images
        current_count = box.contents.length
        first_id = box.contents.first.id.to_s

        auth_post "/@spontaneous/shard/#{job1.id}/#{box.schema_id.to_s}", "filename" => "rose.jpg", "shards" => hashes, "mime_type" => "image/jpeg"
        assert last_response.ok?, "Should have got status 200 but got #{last_response.status}"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        box = job1.reload.images
        first = box.contents.first
        box.contents.length.must_equal current_count+1
        first.image.src.must_match %r{^(.+)/rose\.jpg$}
        required_response = {
          :position => 0,
          :entry => first.export
        }
        Spot::JSON.parse(last_response.body).must_equal required_response
      end
    end

    describe "/page" do
      before do
        @update_slug = "/@spontaneous/page/#{project1.id}/slug"
        @page = project1
      end

      it "return json for individual pages" do
        page = site.home.children.first
        auth_get "/@spontaneous/page/#{page.id}"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        assert_equal S::JSON.encode(page.export), last_response.body
      end

      it "respect user levels in page json" do
        page = AdminAccess.create
        auth_get "/@spontaneous/page/#{page.id}"
        result = Spot::JSON.parse(last_response.body)
        result[:fields].map { |f| f[:name] }.must_equal ["title"]
      end

      it "allows editing of paths" do
        @page.path.must_equal '/project1'
        auth_put @update_slug, 'slug' => 'howabout'
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        @page.reload
        @page.path.must_equal "/howabout"
        Spot::JSON.parse(last_response.body).must_equal({:path => '/howabout', :slug => 'howabout' })
      end

      it "raises an error when trying to save duplicate paths" do
        auth_put @update_slug, 'slug' => 'project2'
        last_response.status.must_equal 409
        @page.reload.path.must_equal '/project1'
      end

      it "raises an error when trying to save an empty slug" do
        auth_put @update_slug, 'slug' => ''
        last_response.status.must_equal 406
        @page.reload.path.must_equal '/project1'
        auth_put @update_slug
        last_response.status.must_equal 406
        @page.reload.path.must_equal '/project1'
      end

      it "provides a list of unavailable slugs for a page" do
        auth_get "#{@update_slug}/unavailable"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        Spot::JSON.parse(last_response.body).must_equal %w(project2 project3)
      end

      it "allows for syncing slugs with the page title" do
        @page.title = "This is Project"
        @page.save
        auth_put "#{@update_slug}/sync"
        assert last_response.ok?
        last_response.content_type.must_equal "application/json;charset=utf-8"
        @page.reload
        @page.path.must_equal "/this-is-project"
        Spot::JSON.parse(last_response.body).must_equal({:path => '/this-is-project', :slug => 'this-is-project' })
      end

      it "allows UID editing by developer level users" do
        user.update(:level => Spontaneous::Permissions[:root])
        uid = "fishy"
        project1.uid.wont_equal uid
        auth_put "/@spontaneous/page/#{project1.id}/uid", 'uid' => uid
        assert last_response.ok?
        Spot::JSON.parse(last_response.body).must_equal({:uid => uid})
        project1.reload.uid.must_equal uid
        user.update(:level => Spontaneous::Permissions[:editor])
      end

      it "disallows UID editing by non-developer level users" do
        uid = "boom"
        orig = project1.uid
        project1.uid.wont_equal uid
        auth_put "/@spontaneous/page/#{project1.id}/uid", 'uid' => uid
        assert last_response.status == 403
        project1.reload.uid.must_equal orig
      end
    end

    describe "/changes" do
      before do
        S::Permissions::UserLevel[:editor].stubs(:can_publish?).returns(true)
      end

      it "be able to retrieve a serialised list of all unpublished changes" do
        auth_get "/@spontaneous/changes"
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        last_response.body.must_equal S::Change.serialise_http(site)
      end

      it "be able to start a publish with a set of change sets" do
        site.expects(:publish_pages).with([project1.id], instance_of(Spontaneous::Permissions::User))
        auth_post "/@spontaneous/changes", :page_ids => [project1.id]
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
      end

      it "not launch publish if list of changes is empty" do
        site.expects(:publish_pages).with().never
        auth_post "/@spontaneous/changes", :change_set_ids => ""
        assert last_response.status == 400, "Expected 400, recieved #{last_response.status}"

        auth_post "/@spontaneous/changes", :change_set_ids => nil
        assert last_response.status == 400
      end

      it "recognise when the list of changes is complete" do
        site.expects(:publish_pages).with([home.id, project1.id], instance_of(Spontaneous::Permissions::User))
        auth_post "/@spontaneous/changes", :page_ids => [home.id, project1.id]
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
      end

      it "passes the logged in user to the publish process" do
        site.expects(:publish_pages).with([home.id, project1.id], user)
        auth_post "/@spontaneous/changes", :page_ids => [home.id, project1.id]
        assert last_response.ok?, "Expected 200 recieved #{last_response.status}"
      end
    end

    describe "/alias" do
      it "retrieves a list of potential targets" do
        auth_get "/@spontaneous/alias/#{LinkedJob.schema_id}/#{home.id}/#{home.in_progress.schema_id}"
        assert last_response.ok?
        expected = LinkedJob.targets(home, home.in_progress)
        response = Spot::JSON.parse(last_response.body)
        response[:pages].must_equal 1
        response[:page].must_equal 1
        response[:total].must_equal expected.length

        response[:targets].must_equal expected.map { |job|
          { :id => job.id,
            :title => job.title.to_s,
            :icon => job.image.export }
        }
      end

      it "filters targets using a search string" do
        auth_get "/@spontaneous/alias/#{LinkedJob.schema_id}/#{home.id}/#{home.in_progress.schema_id}", {"query" => "job 3"}
        assert last_response.ok?
        expected = [job3]
        response = Spot::JSON.parse(last_response.body)
        response[:pages].must_equal 1
        response[:page].must_equal 1
        response[:total].must_equal expected.length
        response[:targets].must_equal expected.map { |job|
          { :id => job.id,
            :title => job.title.to_s,
            :icon => job.image.export }
        }
      end

      it "adds an alias to a box" do
        home.featured_jobs.contents.length.must_equal 0
        auth_post "/@spontaneous/alias/#{home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_ids' => Job.first.id, "position" => 0
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.featured_jobs.contents.length.must_equal 1
        a = home.featured_jobs.first
        assert a.alias?
        a.target.must_equal Job.first
        required_response = {
          :position => 0,
          :entry => home.featured_jobs.contents.first.export(user)
        }
        Spot::JSON.parse(last_response.body).first.must_equal required_response
      end

      it "allows for adding multiple aliases to a box" do
        home.featured_jobs.contents.length.must_equal 0
        jobs = Job.all[0..1]
        auth_post "/@spontaneous/alias/#{home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_ids' => jobs.map(&:id), "position" => 0
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        home.reload
        home.featured_jobs.contents.length.must_equal 2
        home.featured_jobs.each_with_index do |a, i|
          assert a.alias?
          a.target.must_equal jobs[i]
        end
        response = Spot::JSON.parse(last_response.body)
        response[0][:position].must_equal 0
        response[1][:position].must_equal 1
        response[0][:entry].must_equal home.featured_jobs[0].export(user)
        response[1][:entry].must_equal home.featured_jobs[1].export(user)
      end

      it "adds an alias to a box at any position" do
        home.featured_jobs << Job.new
        home.featured_jobs << Job.new
        home.featured_jobs << Job.new
        home.save.reload
        home.featured_jobs.contents.length.must_equal 3
        auth_post "/@spontaneous/alias/#{home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_ids' => Job.first.id, "position" => 2
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.featured_jobs.contents.length.must_equal 4
        a = home.featured_jobs[2]
        assert a.alias?
        a.target.must_equal Job.first
        required_response = {
          :position => 2,
          :entry => home.featured_jobs[2].export(user)
        }
        Spot::JSON.parse(last_response.body).first.must_equal required_response
      end

      it 'adds a hidden alias if the target is hidden' do
        home.featured_jobs.contents.length.must_equal 0
        job = Job.first
        job.hide!
        auth_post "/@spontaneous/alias/#{home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_ids' => job.id, "position" => 0
        assert last_response.ok?, "Recieved #{last_response.status} not 200"
        last_response.content_type.must_equal "application/json;charset=utf-8"
        home.reload
        home.featured_jobs.contents.length.must_equal 1
        a = home.featured_jobs.first
        assert a.hidden?
      end


      it "interfaces with lists of non-content targets" do
        begin
          @target_id = target_id = 9999
          @target = target = mock()
          @target.stubs(:id).returns(@target_id)
          @target.stubs(:title).returns("custom object")
          @target.stubs(:to_json).returns({:title => "custom object", :id => @target_id}.to_json)
          @target.stubs(:alias_title).returns("custom object")
          @target.stubs(:exported_alias_icon).returns(nil)

          ::LinkedSomething = Class.new(Piece) do
            alias_of proc { [target] }, :lookup => lambda { |id|
              return target if id == target_id
              nil
            }
          end
          box = home.boxes[:featured_jobs]
          box._prototype.allow LinkedSomething
          auth_post "/@spontaneous/alias/#{home.id}/#{box.schema_id.to_s}", 'alias_id' => LinkedSomething.schema_id.to_s, 'target_ids' => @target_id, "position" => 0
          assert last_response.status == 200, "Expected a 200 but got #{last_response.status}"
          home.reload
          a = home.featured_jobs[0]
          assert a.alias?
          a.target.must_equal @target
        ensure
          Object.send(:remove_const, LinkedSomething) rescue nil
        end
      end
    end

    describe "/asset" do
      it "return scripts from js dir" do
        get '/@spontaneous/js/test.js'
        assert last_response.ok?, "Expected a 200 but received a #{last_response.status}"
        last_response.content_type.must_equal "application/javascript;charset=UTF-8"
        # Sprockets appends sone newlines and a semicolon onto our test file
        assert_equal File.read(@app_dir / 'js/test.js') + "\n;\n", last_response.body
      end

      it "work for site public files" do
        get "/test.html"
        assert last_response.ok?
        assert_equal (<<-HTML).gsub(/^\s+/, ''), last_response.body
        <html><head><title>Test</title></head></html>
        HTML
      end

      it "work for @spontaneous files" do
        get "/@spontaneous/static/test.html"
        assert last_response.ok?
        assert_equal (<<-HTML).gsub(/^\s+/, ''), last_response.body
          <html><head><title>@spontaneous Test</title></head></html>
        HTML
      end
      # should "return a custom favicon" do
      #   get "/favicon.ico"
      #   assert last_response.ok?
      #   p @app_dir
      #   assert_equal File.read(@app_dir / 'static/favicon.ico'), last_response.body
      # end
    end


    describe "/events" do
      it "should require CSRF header" do
        get "/@spontaneous/events"
        assert last_response.status == 401
      end

      it "should disable buffering" do
        auth_get "/@spontaneous/events", {}, {"HTTP_ACCEPT" => "text/event-stream"}
        last_response.headers["X-Accel-Buffering"].must_equal "no"
      end

      it "should have a content type of text/event-stream" do
        auth_get "/@spontaneous/events", {}, {"HTTP_ACCEPT" => "text/event-stream"}
        last_response.headers["Content-Type"].must_match /^text\/event-stream/
      end
    end
  end

  describe "/" do
    before do
      @renderer = Spontaneous::Output.preview_renderer(site)
    end

    def get_preview(path, params = {}, env = {})
      get path, params, env.merge("HTTP_REFERER" => "http://example.com/@spontaneous/234/edit")
    end

    it "redirects to /@spontaneous unless called from the editing UI" do
      get "/"
      assert last_response.status == 302
      last_response.headers['Location'].must_equal "http://example.org/@spontaneous/#{home.id}/preview"
    end

    it "redirects to the page's preview unless called from the editing UI" do
      get project1.path
      assert last_response.status == 302
      last_response.headers['Location'].must_equal "http://example.org/@spontaneous/#{project1.id}/preview"
    end

    it "shows the page without UI if the 'preview' parameter is set" do
      get project1.path, preview: true
      assert last_response.status == 200
    end

    it "return rendered root page" do
      get_preview "/"
      assert last_response.ok?
      last_response.content_type.must_equal "text/html;charset=utf-8"
      assert_equal @renderer.render(home.output(:html)), last_response.body
    end

    it "return rendered child-page" do
      get_preview "/project1"
      assert last_response.ok?
      last_response.content_type.must_equal "text/html;charset=utf-8"
      assert_equal @renderer.render(project1.output(:html)), last_response.body
    end

    it "return alternate formats" do
      Project.add_output :js
      get_preview "/project1.js"
      assert last_response.ok?
      last_response.content_type.must_equal "application/javascript;charset=utf-8"
      assert_equal @renderer.render(project1.output(:js)), last_response.body
    end

    it "allow pages to have css formats" do
      Project.add_output :css
      get_preview "/project1.css"
      assert last_response.ok?
      last_response.content_type.must_equal "text/css;charset=utf-8"
      assert_equal @renderer.render(project1.output(:css)), last_response.body
    end

    it "return cache-busting headers" do
      ["/project1", "/"].each do |path|
        get_preview path
        assert last_response.ok?
        last_response.headers['Expires'].must_equal @now.to_formatted_s(:rfc822)
        last_response.headers['Last-Modified'].must_equal @now.to_formatted_s(:rfc822)
      end
    end

    it "return cache-control headers" do
      ["/project1", "/"].each do |path|
        get_preview path
        assert last_response.ok?
        ["no-store", 'no-cache', 'must-revalidate', 'max-age=0'].each do |p|
          last_response.headers['Cache-Control'].must_match %r(#{p})
        end
      end
    end

    it "render SASS templates" do
      get "/assets/css/sass_template.css"
      assert last_response.ok?, "Should return 200 but got #{last_response.status}"
      last_response.body.must_match /color: #fef/
    end

    it "compile CoffeeScript" do
      get "/assets/js/coffeescript.js"
      assert last_response.ok?, "Should return 200 but got #{last_response.status}"
      last_response.body.must_match /square = function/
      last_response.content_type.must_equal "application/javascript;charset=UTF-8"
    end

    it "accept POST requests" do
      Project.expects(:posted!).with(project1)
      Project.controller do
        post { Project.posted!(page) }
      end
      post "/project1"
    end

    it "previews hidden pages" do
      get_preview "/project1"
      body = last_response.body
      project1.hide!
      get_preview "/project1"
      assert last_response.ok?, "Expected 200 got #{last_response.status}"
      last_response.body.must_equal body
    end
  end

  describe "/media" do
    it "should be available under /media" do
      get "/media/101/003/rose.jpg"
      assert last_response.ok?
      last_response.content_type.must_equal "image/jpeg"
    end
  end


    describe "/schema" do
      before do
        class ::Modifiable < Piece
          field :title
          field :image
        end
        # enable schema validation errors by creating and using a permanent map file
        @schema_map = File.join(Dir.tmpdir, "schema.yml")
        FileUtils.rm(@schema_map) if File.exists?(@schema_map)
        @schema = S.schema
        @schema.schema_map_file = @schema_map
        @schema.validate!
        @schema.write_schema
        @schema.schema_loader_class = S::Schema::PersistentMap
        @df1 = Modifiable.field_prototypes[:title]
        @f1  = Modifiable.field_prototypes[:image]
        @uid = @df1.schema_id.to_s
        @schema.delete(::Modifiable)
        Object.send :remove_const, :Modifiable

        class ::Modifiable < Piece
          field :replaced
          field :image
        end
        @af1 = Modifiable.field_prototypes[:replaced]
        lambda { @schema.validate! }.must_raise(Spontaneous::SchemaModificationError)
        S::Rack::Back::Reloader.any_instance.stubs(:should_reload?).returns(true)
        Spontaneous::Loader.stubs(:reload!)
      end

      after do
        S.schema.delete(::Modifiable)
        Object.send :remove_const, :Modifiable
        S.schema.schema_loader_class = S::Schema::TransientMap
        FileUtils.rm(@schema_map) if File.exists?(@schema_map)
      end

      it "raise a 412 error" do
        get '/@spontaneous/'
        assert last_response.status == 412, "Schema validation errors should raise a 412 but instead recieved a #{last_response.status}"
      end

      it "present a dialogue page with possible solutions" do
        auth_get '/@spontaneous/'
        assert last_response.status == 412, "Schema validation errors should raise a 412 but instead recieved a #{last_response.status}"
        last_response.body.must_match %r{<form action="/@spontaneous/schema/delete" method="post"}
        last_response.body.must_match %r{<input type="hidden" name="#{S::Rack::CSRF_PARAM}" value=".{32}:[0-9a-f]{40}"}
        last_response.body.must_match %r{<input type="hidden" name="uid" value="#{@df1.schema_id}"}

        last_response.body.must_match %r{<form action="/@spontaneous/schema/rename" method="post"}
        last_response.body.must_match %r{<input type="hidden" name="ref" value="#{@af1.schema_name}"}
      end

      it "present a dialogue page with possible solutions when in preview mode" do
        auth_get '/'
        assert last_response.status == 412, "Schema validation errors should raise a 412 but instead recieved a #{last_response.status}"
        last_response.body.must_match %r{<form action="/@spontaneous/schema/delete" method="post"}
        last_response.body.must_match %r{<input type="hidden" name="#{S::Rack::CSRF_PARAM}" value=".{32}:[0-9a-f]{40}"}
        last_response.body.must_match %r{<input type="hidden" name="uid" value="#{@df1.schema_id}"}

        last_response.body.must_match %r{<form action="/@spontaneous/schema/rename" method="post"}
        last_response.body.must_match %r{<input type="hidden" name="ref" value="#{@af1.schema_name}"}
      end

      it "perform renames via a link" do
        S.schema.expects(:apply_fix).with(:rename, @df1.schema_id.to_s, @af1.schema_name)
        action ="/@spontaneous/schema/rename"
        post action, "uid" => @df1.schema_id, "ref" => @af1.schema_name, "origin" => "/@spontaneous", S::Rack::CSRF_PARAM => api_key.generate_csrf_token
        last_response.status.must_equal 302
      end

      it "perform deletions via a link" do
        S.schema.expects(:apply_fix).with(:delete, @df1.schema_id.to_s)
        action ="/@spontaneous/schema/delete"
        post action, "uid" => @df1.schema_id, "origin" => "/@spontaneous", S::Rack::CSRF_PARAM => api_key.generate_csrf_token
        last_response.status.must_equal 302
      end

      it "redirects back to original page"
    end
end
