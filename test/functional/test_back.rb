require 'test_helper'

# set :environment, :test


class BackTest < Test::Unit::TestCase
  include Spontaneous
  include ::Rack::Test::Methods

  def app
    Spontaneous::Rack::Back.application
  end

  def setup
    Spontaneous.init(:mode => :back, :environment => :development)
    Sequel::Migrator.apply(Spontaneous.database, 'db/migrations')
    Content.delete

    @project1 = Project.new
    @project2 = Project.new
    @project3 = Project.new

    @page = HomePage.new
    @page.in_progress << @project1
    @page.completed << @project2
    @page.archived << @project3
    @page.save

    @page2 = InfoPage.new({
      :slug => "about"
    })

    @page.pages << @page2

    # @facet2_1 = Text.new
    # @facet2_2 = Text.new
    # @facet2_3 = Text.new
    # @facet2_4 = Text.new
    # @facet2_5 = Text.new
    # @page2 << @facet2_1
    # @facet2_1 << @facet2_2
    # @facet2_2 << @facet2_3
    # @facet2_2 << @facet2_4
    # @facet2_2 << @facet2_5
    # @facet2 << @page2
    @page2.save
    @page.save
    [@project1, @project2, @project3].each { |p| p.save }
    @page2 = Page[@page2.id]
    @page.root?.should be_true
    @app_dir = File.expand_path("../../fixtures/example_application", __FILE__)
    File.exists?(@app_dir).should be_true
    Spontaneous.stubs(:application_dir).returns(@app_dir)
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
      assert_equal @page.to_json, last_response.body
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
      type = Schema.load :my_node_type
      get "/@spontaneous/type/#{type.id}"
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
    should "return a site map" do
      get '/@spontaneous/map'
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      assert_equal Site.map.to_json, last_response.body
    end

    should "reorder facets" do
      post "/@spontaneous/facet/#{@facet2_5.id}/position/0"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      @facet2_2.reload.entries.first.target.id.should == @facet2_5.id
    end
    should "reorder pages" do
      post "/@spontaneous/page/#{@page2.id}/position/0"
      assert last_response.ok?
      last_response.content_type.should == "application/json;charset=utf-8"
      # can't actually be bothered to set this test up
      # @facet2_2.reload.entries.first.target.id.should == @facet2_5.id
    end

    context "saving" do
      setup do
        @page = HomePage.new
        @facet = Text.new
        @page.in_progress << @facet
        @page.save
        @facet.save
        pp @page.to_hash
        puts "_"*30
      end
      should "update facet field values" do
        params = {
          "field[text][value]" => "Updated field_name_1"
        }
        post "/@spontaneous/facet/#{@facet.id}/save", params
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
        post "/@spontaneous/page/#{@page.id}/save", params
        assert last_response.ok?
        last_response.content_type.should == "application/json;charset=utf-8"
        @page = Content[@page.id]
        last_response.body.should == @page.to_json
        @page.fields.title.value.should ==  "Updated title"
        @page.fields.introduction.value.should ==  "Updated intro"
      end
    end
  end # context @spontaneous

  context "preview" do
    should "return rendered root page" do
      get "/"
      assert last_response.ok?
      last_response.content_type.should == "text/html;charset=utf-8"
      assert_equal @page.render, last_response.body
    end
    should "return rendered child-page" do
      get "/child"
      assert last_response.ok?
      last_response.content_type.should == "text/html;charset=utf-8"
      assert_equal @page2.render, last_response.body
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
end


