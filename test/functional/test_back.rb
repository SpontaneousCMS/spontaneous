# encoding: UTF-8

require 'test_helper'

# set :environment, :test


class BackTest < Test::Unit::TestCase
  include ::Rack::Test::Methods

  def app
    Spontaneous::Rack::Back.application
  end

  def teardown
    teardown_site_fixture
  end

  def setup
    setup_site_fixture
  end

  context "@spontaneous" do
    setup do
    end

    should "return application page" do
      get '/@spontaneous/'
      assert last_response.ok?
      last_response.body.should =~ /<title>Spontaneous<\/title>/
      get '/@spontaneous'
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

    should "return json for a specific type" do
      type = InfoPage
      get "/@spontaneous/type/#{type.json_name}"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      assert_equal type.to_json, last_response.body
    end

    should "return scripts from js dir" do
      get '/@spontaneous/js/test.js'
      assert last_response.ok?
      last_response.content_type.should == "text/javascript; charset=utf-8"
      assert_equal File.read(@app_dir / 'js/test.js'), last_response.body
    end

    should "return less rendered to css from css dir" do
      get '/@spontaneous/css/test.css'
      assert last_response.ok?
      last_response.content_type.should == "text/css; charset=utf-8"
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
      page = @about
      get "/@spontaneous/location#{@about.path}"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      assert_equal Site.map(@about.id).to_json, last_response.body
    end

    should "reorder facets" do
      post "/@spontaneous/content/#{@facet2_5.id}/position/0"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      @about.text.entries.first.id.should == @facet2_5.id

      p = Content[@about.id]
      p.text.entries.first.id.should == @facet2_5.id
    end
    # should "reorder pages" do
    #   post "/@spontaneous/page/#{@about.id}/position/0"
    #   assert last_response.ok?
    #   last_response.content_type.should == "application/json;charset=utf-8"
    #   # can't actually be bothered to set this test up
    #   # @facet2_2.reload.entries.first.target.id.should == @facet2_5.id
    # end

    context "saving" do
      setup do
        @home = HomePage.new
        @facet = Text.new
        @home.in_progress << @facet
        @home.save
        @facet.save
      end

      should "update content field values" do
        params = {
          "field[text][value]" => "Updated field_name_1"
        }
        post "/@spontaneous/save/#{@facet.id}", params
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @facet = Content[@facet.id]
        last_response.body.should == @facet.to_json
        @facet.fields.text.value.should ==  "<p>Updated field_name_1</p>\n"
      end
      should "update page field values" do
        params = {
          "field[title][value]" => "Updated title",
          "field[introduction][value]" => "Updated intro"
        }
        post "/@spontaneous/save/#{@home.id}", params
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @home = Content[@home.id]
        last_response.body.should == @home.to_json
        @home.fields.title.value.should ==  "Updated title"
        @home.fields.introduction.value.should ==  "<p>Updated intro</p>\n"
      end
    end
  end # context @spontaneous

  context "preview" do
    should "return rendered root page" do
      get "/"
      assert last_response.ok?
      last_response.content_type.should == "text/html;charset=utf-8"
      assert_equal @home.render, last_response.body
    end

    should "return rendered child-page" do
      get "/about"
      assert last_response.ok?
      last_response.content_type.should == "text/html;charset=utf-8"
      assert_equal @about.render, last_response.body
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
    should "return a custom favicon" do
      get "favicon.ico"
      assert last_response.ok?
      assert_equal File.read(@app_dir / 'static/favicon.ico'), last_response.body
    end
  end
  context "media files" do
    setup do
      @media_dir = File.join(File.dirname(__FILE__), "../fixtures/media")
      Spontaneous.media_dir = @media_dir
    end
    should "be available under /media" do
      get "/media/101/003/rose.jpg"
      assert last_response.ok?
      last_response.content_type.should == "image/jpeg"
    end
  end
  context "file uploads" do
    setup do
      @media_dir = File.join(File.dirname(__FILE__), "../../tmp/media")
      Spontaneous.media_dir = @media_dir
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
      @barakapoint.image.processed_value.should == ""
      post "@spontaneous/file/replace/#{@barakapoint.id}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg"), "field" => 'image'
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      @barakapoint.reload
      src = @barakapoint.image.src
      src.should =~ /^\/media(.+)\/rose\.jpg$/
      last_response.body.should == {
        :id => @barakapoint.id,
        :src => src
      }.to_json
      File.exist?(Media.to_filepath(src)).should be_true
      get src
      assert last_response.ok?
    end

    should "be able to wrap entries around files using default addable class" do
      slot = @home.in_progress
      current_count = slot.entries.length
      first_id = slot.entries.first.id

      post "/@spontaneous/file/wrap/#{slot.id}", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg")
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      slot = @home.reload.in_progress
      first = slot.entries.first
      slot.entries.length.should == current_count+1
      first.image.src.should =~ /^\/media(.+)\/#{File.basename(@src_file)}$/
      required_response = {
        :position => 0,
        :entry => first.to_hash
      }
      last_response.body.json.should == required_response
    end
  end
  context "Entries" do
    should "be addable" do
      current_count = @home.in_progress.entries.length
      first_id = @home.in_progress.entries.first.id
      @home.in_progress.entries.first.class.name.should_not == "ProjectImage"
      post "/@spontaneous/add/#{@home.in_progress.id}/ProjectImage"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      @home.reload
      @home.in_progress.entries.length.should == current_count+1
      @home.in_progress.entries.first.id.should_not == first_id
      @home.in_progress.entries.first.class.name.should == "ProjectImage"
      required_response = {
        :position => 0,
        :entry => @home.in_progress.entries.first.to_hash
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
      @about.path.should == '/about'
      post "/@spontaneous/slug/#{@about.id}", 'slug' => 'howabout'
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      @about.reload
      @about.path.should == "/howabout"
      last_response.body.json.should == {:path => '/howabout' }
    end
    should "raise error when trying to save duplicate path" do
      post "/@spontaneous/slug/#{@about.id}", 'slug' => 'projects'
      last_response.status.should == 409
      @about.reload.path.should == '/about'
    end
    should "raise error when trying to save empty slug" do
      post "/@spontaneous/slug/#{@about.id}", 'slug' => ''
      last_response.status.should == 406
      @about.reload.path.should == '/about'
      post "/@spontaneous/slug/#{@about.id}"
      last_response.status.should == 406
      @about.reload.path.should == '/about'
    end
    should "provide a list of unavailable slugs for a page" do
      get "/@spontaneous/slug/#{@about.id}/unavailable"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      last_response.body.json.should == %w(projects products)
    end
  end
end


