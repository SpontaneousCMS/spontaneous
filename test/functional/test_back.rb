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
        @facet.fields.text.value.should ==  "Updated field_name_1"
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
      post "@spontaneous/upload/9723", "file" => ::Rack::Test::UploadedFile.new(@src_file, "image/jpeg")
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      assert_equal({
        :id => '9723',
        :path => "/media/tmp/1288882153.23/rose.jpg"
      }.to_json, last_response.body)
    end
  end
end


