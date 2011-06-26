# encoding: UTF-8

require 'test_helper'

# set :environment, :test


class BackTest < MiniTest::Spec
  include ::Rack::Test::Methods


  def self.startup
    # Spontaneous.logger = nil
    Spontaneous.logger.silent!
  end

  def self.shutdown
  end

  def app
    Spontaneous::Rack::Back.application
  end

  def teardown
    # teardown_site_fixture
  end

  def setup
    @media_dir = File.expand_path('../../../tmp/media', __FILE__)
    Spontaneous.media_dir = @media_dir
  end
  def teardown
    ::FileUtils.rm_rf(@media_dir)
  end

  context "Editing interface" do
    setup do
      Spot::Schema.reset!
      Content.delete
      Spontaneous::Permissions::User.delete
      Spontaneous.template_root = File.expand_path('../../fixtures/back/templates', __FILE__)
      Spontaneous.root = File.expand_path("../../fixtures/back", __FILE__)
      @app_dir = File.expand_path("../../fixtures/application", __FILE__)
      File.exists?(@app_dir).should be_true
      Spontaneous.stubs(:application_dir).returns(@app_dir)
      # setup_site_fixture
      # annoying to have to do this, but there you go
      @user = Spontaneous::Permissions::User.create(:email => "root@example.com", :login => "root", :name => "root", :password => "rootpass", :password_confirmation => "rootpass")
      @user.update(:level => Spontaneous::Permissions.root)
      @user.save
      Spontaneous::Permissions.stubs(:active_user).returns(@user)

      class Page < Spot::Page
        field :title
      end
      class Piece < Spot::Piece; end
      class Project < Page; end
      class Image < Piece
        field :image, :image
      end

      class Job < Piece
        field :title
        field :image, :image

        box :images do
          field :title
          allow Image
        end
      end

      class LinkedJob < Piece
        alias_of Job
      end

      class HomePage < Page
        field :introduction, :text
        box :projects do
          allow Project
        end
        box :in_progress do
          allow Job
        end

        box :featured_jobs do
          allow LinkedJob
        end
      end

      @home = HomePage.new(:title => "Home")
      @project1 = Project.new(:title => "Project 1", :slug => "project1")
      @project2 = Project.new(:title => "Project 2", :slug => "project2")
      @project3 = Project.new(:title => "Project 3", :slug => "project3")
      @home.projects << @project1
      @home.projects << @project2
      @home.projects << @project3

      @job1 = Job.new(:title => "Job 1", :image => "/i/job1.jpg")
      @job2 = Job.new(:title => "Job 2", :image => "/i/job2.jpg")
      @job3 = Job.new(:title => "Job 3", :image => "/i/job3.jpg")
      @image1 = Image.new
      @job1.images << @image1
      @home.in_progress << @job1
      @home.in_progress << @job2
      @home.in_progress << @job3

      @home.save
      @home = Content[@home.id]
    end

    teardown do
      [:Page, :Piece, :HomePage, :Job, :Project, :Image, :LinkedJob].each { |klass| BackTest.send(:remove_const, klass) rescue nil }
      Spontaneous::Permissions::User.delete
    end

    context "@spontaneous" do
      setup do
      end

      should "return application page" do
        get '/@spontaneous/'
        assert last_response.ok?
        last_response.body.should =~ /<title>Spontaneous<\/title>/
      end

      should "return json for root page" do
        get '/@spontaneous/root'
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.root.to_json, last_response.body
      end

      should "return json for individual pages" do
        page = Site.root.children.first
        get "/@spontaneous/page/#{page.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal page.to_json, last_response.body
      end

      should "return json for all types" do
        get "/@spontaneous/types"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Schema.to_hash.to_json, last_response.body
      end

      # should "return json for a specific type" do
      #   type = InfoPage
      #   get "/@spontaneous/type/#{type.json_name}"
      #   puts last_response.body
      #   assert last_response.ok?
      #   last_response.content_type.should == "application/json;charset=utf-8"
      #   assert_equal type.to_json, last_response.body
      # end

      should "return scripts from js dir" do
        get '/@spontaneous/js/test.js'
        assert last_response.ok?
        # last_response.content_type.should == "application/javascript;charset=utf-8"
        last_response.content_type.should == "application/javascript"
        assert_equal File.read(@app_dir / 'js/test.js'), last_response.body
      end

      should "return less rendered to css from css dir" do
        get '/@spontaneous/css/test.css'
        assert last_response.ok?
        last_response.content_type.should == "text/css;charset=utf-8"
        assert_equal "h1 { color: #4d926f; }\n", last_response.body
      end

      should "return a site map for root by default" do
        get '/@spontaneous/map'
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.map.to_json, last_response.body
      end

      should "return a site map for any page id" do
        get "/@spontaneous/map/#{@home.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.map(@home.id).to_json, last_response.body
      end

      should "return a site map for any url" do
        page = @project1
        get "/@spontaneous/location#{@project1.path}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal Site.map(@project1.id).to_json, last_response.body
      end

      should "return 404 when asked for map of non-existant page" do
        id = '9999'
        S::Content.stubs(:[]).with(id).returns(nil)
        get "/@spontaneous/map/#{id}"
        assert last_response.status == 404
      end

      should "reorder pieces" do
        post "/@spontaneous/content/#{@job2.id}/position/0"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.in_progress.pieces.first.id.should == @job2.id

        page = Content[@home.id]
        page.in_progress.pieces.first.id.should == @job2.id
      end

      # should "reorder pages" do
      #   post "/@spontaneous/page/#{@about.id}/position/0"
      #   assert last_response.ok?
      #   last_response.content_type.should == "application/json;charset=utf-8"
      #   # can't actually be bothered to set this test up
      #   # @piece2_2.reload.pieces.first.target.id.should == @piece2_5.id
      # end

      context "saving" do
        setup do
          # @home = HomePage.new
          # @piece = Text.new
          # @home.in_progress << @piece
          # @home.save
          # @piece.save
        end

        should "update content field values" do
          params = {
            "field[#{@job1.fields.title.schema_id.to_s}][value]" => "Updated field_name_1"
          }
          post "/@spontaneous/save/#{@job1.id}", params
          assert last_response.ok?
          last_response.content_type.should == "application/json;charset=utf-8"
          @job1 = Content[@job1.id]
          last_response.body.should == @job1.to_json
          @job1.fields.title.value.should ==  "Updated field_name_1"
        end

        should "update page field values" do
          params = {
            "field[#{@home.fields.title.schema_id.to_s}][value]" => "Updated title",
            "field[#{@home.fields.introduction.schema_id.to_s}][value]" => "Updated intro"
          }
          post "/@spontaneous/save/#{@home.id}", params
          assert last_response.ok?
          last_response.content_type.should == "application/json;charset=utf-8"
          @home = Content[@home.id]
          last_response.body.should == @home.to_json
          @home.fields.title.value.should ==  "Updated title"
          @home.fields.introduction.value.should ==  "<p>Updated intro</p>\n"
        end
        should "update box field values" do
          box = @job1.images
          box.fields.title.to_s.should_not == "Updated title"
          params = {
            "field[#{box.fields.title.schema_id.to_s}][value]" => "Updated title"
          }
          post "/@spontaneous/savebox/#{@job1.id}/#{box.schema_id.to_s}", params
          assert last_response.ok?
          last_response.content_type.should == "application/json;charset=utf-8"
          @job1 = Content[@job1.id]
          @job1.images.title.value.should == "Updated title"
        end

      end
    end # context @spontaneous

    context "Visibility" do
      setup do
        # @home = HomePage.new
        # @piece = Text.new
        # @home.in_progress << @piece
        # @home.save
        # @piece.save
      end
      should "be toggled" do
        @job1.reload.visible?.should == true
        post "/@spontaneous/toggle/#{@job1.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        last_response.body.json.should == {:id => @job1.id, :hidden => true}
        @job1.reload.visible?.should == false
        post "/@spontaneous/toggle/#{@job1.id}"
        assert last_response.ok?
        @job1.reload.visible?.should == true
        last_response.body.json.should == {:id => @job1.id, :hidden => false}
      end
    end

    context "preview" do
      setup do
        @now = Time.now
        Time.stubs(:now).returns(@now)
      end
      should "return rendered root page" do
        get "/"
        assert last_response.ok?
        last_response.content_type.should == "text/html;charset=utf-8"
        assert_equal S::Render.with_preview_renderer { @home.render }, last_response.body
      end

      should "return rendered child-page" do
        get "/project1"
        assert last_response.ok?
        last_response.content_type.should == "text/html;charset=utf-8"
        assert_equal S::Render.with_preview_renderer { @project1.render }, last_response.body
      end

      should "return cache-busting headers" do
        ["/project1", "/"].each do |path|
          get path
          assert last_response.ok?
          last_response.headers['Expires'].should == @now.to_formatted_s(:rfc822)
          last_response.headers['Last-Modified'].should == @now.to_formatted_s(:rfc822)
        end
      end

      should "return cache-control headers" do
        ["/project1", "/"].each do |path|
          get path
          assert last_response.ok?
          ["no-store", 'no-cache', 'must-revalidate', 'max-age=0'].each do |p|
            last_response.headers['Cache-Control'].should =~ %r(#{p})
          end
        end
      end
    end

    context "static files" do
      should "work for site" do
        get "/test.html"
        assert last_response.ok?
        assert_equal <<-HTML, last_response.body
<html><head><title>Test</title></head></html>
        HTML
      end
      should "work for @spontaneous files" do
        get "/@spontaneous/static/test.html"
        assert last_response.ok?
        assert_equal <<-HTML, last_response.body
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
    context "media files" do
      setup do
        Spontaneous.media_dir = File.join(File.dirname(__FILE__), "../fixtures/media")
      end
      teardown do
      end
      should "be available under /media" do
        get "/media/101/003/rose.jpg"
        assert last_response.ok?
        last_response.content_type.should == "image/jpeg"
      end
    end
    context "file uploads" do
      setup do
        @src_file = Pathname.new(File.join(File.dirname(__FILE__), "../fixtures/images/rose.jpg")).realpath.to_s
        @upload_id = 9723
        Time.stubs(:now).returns(Time.at(1288882153))
        Spontaneous::Media.stubs(:upload_index).returns(23)
      end

      should "create a file in a safe subdirectory of media/tmp" do
        post "@spontaneous/file/upload/9723", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg")
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        assert_equal({
          :id => '9723',
          :src => "/media/tmp/1288882153.23/rose.jpg",
          :path => "#{Spontaneous.media_dir}/tmp/1288882153.23/rose.jpg"
        }.to_json, last_response.body)
      end

      should "replace values of fields immediately when required" do
        @image1.image.processed_value.should == ""
        post "@spontaneous/file/replace/#{@image1.id}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg"), "field" => @image1.image.schema_id.to_s
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @image1 = Content[@image1.id]
        src = @image1.image.src
        src.should =~ /^\/media(.+)\/rose\.jpg$/
        last_response.body.should == {
          :id => @image1.id,
          :src => src
        }.to_json
        File.exist?(Media.to_filepath(src)).should be_true
        get src
        assert last_response.ok?
      end

      should "be able to wrap pieces around files using default addable class" do
        box = @job1.images
        current_count = box.pieces.length
        first_id = box.pieces.first.id.to_s

        post "/@spontaneous/file/wrap/#{@job1.id}/#{box.schema_id.to_s}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg")
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        box = @job1.reload.images
        first = box.pieces.first
        box.pieces.length.should == current_count+1
        first.image.src.should =~ /^\/media(.+)\/#{File.basename(@src_file)}$/
          required_response = {
          :position => 0,
          :entry => first.to_hash
        }
        last_response.body.json.should == required_response
      end
    end
    context "pieces" do
      should "be addable" do
        current_count = @home.in_progress.pieces.length
        first_id = @home.in_progress.pieces.first.id
        @home.in_progress.pieces.first.class.name.should_not == "BackTest::Image"
        post "/@spontaneous/add/#{@home.id}/#{@home.in_progress.schema_id.to_s}/#{Image.schema_id.to_s}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.in_progress.pieces.length.should == current_count+1
        @home.in_progress.pieces.first.id.should_not == first_id
        @home.in_progress.pieces.first.class.name.should == "BackTest::Image"
        required_response = {
          :position => 0,
          :entry => @home.in_progress.pieces.first.to_hash
        }
        last_response.body.json.should == required_response.to_hash
      end

      should "be removable" do
        target = @home.in_progress.first
        post "/@spontaneous/destroy/#{target.id}"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        Content[target.id].should be_nil
      end
    end

    context "Page paths" do
      should "be editable" do
        @project1.path.should == '/project1'
        post "/@spontaneous/slug/#{@project1.id}", 'slug' => 'howabout'
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @project1.reload
        @project1.path.should == "/howabout"
        last_response.body.json.should == {:path => '/howabout' }
      end
      should "raise error when trying to save duplicate path" do
        post "/@spontaneous/slug/#{@project1.id}", 'slug' => 'project2'
        last_response.status.should == 409
        @project1.reload.path.should == '/project1'
      end
      should "raise error when trying to save empty slug" do
        post "/@spontaneous/slug/#{@project1.id}", 'slug' => ''
        last_response.status.should == 406
        @project1.reload.path.should == '/project1'
        post "/@spontaneous/slug/#{@project1.id}"
        last_response.status.should == 406
        @project1.reload.path.should == '/project1'
      end
      should "provide a list of unavailable slugs for a page" do
        get "/@spontaneous/slug/#{@project1.id}/unavailable"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        last_response.body.json.should == %w(project2 project3)
      end
    end
    context "Request cache" do
      setup do
        # @home = HomePage.new
        # @piece = Text.new
        # @home.in_progress << @piece
        # @home.save
        # @piece.save
        Change.delete
      end
      should "wrap all updates in a Change.record" do
        params = {
          "field[#{@job1.fields.title.schema_id.to_s}][value]" => "Updated field_name_1"
        }
        Change.count.should == 0
        post "/@spontaneous/save/#{@job1.id}", params
        Change.count.should == 1
        Change.first.modified_list.should == [@home.id]
      end

    end

    context "Publishing" do
      setup do
        @now = Time.now
        Time.stubs(:now).returns(@now)
        Change.delete
        @c1 = Change.new
        @c1.push(@home)
        @c1.push(@project1)
        @c1.save
        @c2 = Change.new
        @c2.push(@home)
        @c2.push(@project1)
        @c2.save
      end

      teardown do
        Change.delete
      end

      should "be able to retrieve a serialised list of all unpublished changes" do
        get "/@spontaneous/publish/changes"
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        last_response.body.should == Change.outstanding.to_json
      end

      should "be able to start a publish with a set of change sets" do
        Site.expects(:publish_changes).with([@c1.id])
        post "/@spontaneous/publish/publish", :change_set_ids => [@c1.id]
        assert last_response.ok?
      end

      should "not launch publish if list of changes is empty" do
        Site.expects(:publish_changes).with().never
        post "/@spontaneous/publish/publish", :change_set_ids => ""
        assert last_response.status == 400, "Expected 400, recieved #{last_response.status}"

        post "/@spontaneous/publish/publish", :change_set_ids => nil
        assert last_response.status == 400
      end
      should "recognise when the list of changes is complete" do
        Site.expects(:publish_changes).with([@c1.id, @c2.id])
        post "/@spontaneous/publish/publish", :change_set_ids => [@c1.id, @c2.id]
        assert last_response.ok?
      end

      should "be able to retrieve the publishing status" do
        Site.publishing_method.status = "something:50"
        get "/@spontaneous/publish/status"
        assert last_response.ok?
        last_response.body.should == {:status => "something", :progress => "50"}.to_json
      end
    end

    context "New sites" do
      setup do
        @root_class = Site.root.class
        Content.delete
        Change.delete
      end
      should "raise a 406 Not Acceptable error when downloading page details" do
        get "/@spontaneous/location/"
        last_response.status.should == 406
      end
      should "create a homepage of the specified type" do
        post "/@spontaneous/root", 'type' => @root_class.schema_id
        assert last_response.ok?
        Site.root.must_be_instance_of(@root_class)
        Site.root.title.value.should =~ /Home/
      end
      should "only create one root" do
        post "/@spontaneous/root", 'type' => @root_class.schema_id
        assert last_response.ok?
        Content.count.should == 1
        post "/@spontaneous/root", 'type' => @root_class.schema_id
        assert last_response.status == 403
        Content.count.should == 1
      end
      should "have a change reflecting creation of root" do
        Change.count.should == 0
        post "/@spontaneous/root", 'type' => @root_class.schema_id
        Change.count.should == 1
      end
    end

    context "Aliases" do
      setup do
      end

      teardown do
      end

      should "be able to retrieve a list of potential targets" do
        get "/@spontaneous/targets/#{LinkedJob.schema_id}"
        assert last_response.ok?
        last_response.body.json.should == LinkedJob.targets.map do |job|
          {
            :id => job.id,
            :title => job.title.to_s,
            :icon => job.image.to_hash
          }
        end
      end
      should "be able to add an alias to a box" do
        @home.featured_jobs.pieces.length.should == 0
        post "/@spontaneous/alias/#{@home.id}/#{HomePage.boxes[:featured_jobs].schema_id.to_s}", 'alias_id' => LinkedJob.schema_id.to_s, 'target_id' => Job.first.id
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @home.reload
        @home.featured_jobs.pieces.length.should == 1
        a = @home.featured_jobs.first
        a.alias?.should be_true
        a.target.should == Job.first
        required_response = {
          :position => 0,
          :entry => @home.featured_jobs.pieces.first.to_hash
        }
        last_response.body.json.should == required_response.to_hash
      end
    end
  end
end

