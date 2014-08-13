# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


describe "Site" do

  before do
    @site = setup_site
    @site.config.tap do |c|
      c.site_domain = "spontaneous.io"
    end
    Content.delete
    Page.field :title
    Page.box   :subpages
  end

  after do
    teardown_site
  end

  def assert_site_modified(time)
    (@site.modified_at - time).must_be :<=, 1
  end

  describe "contents" do
    before do
      @root = ::Page.new
      @root.title = "Homepage"
      @page1_1 = ::Page.new(:slug => "page1-1")
      @page1_1.title = "Page 1 1"
      @page1_2 = ::Page.new(:slug => "page1-2")
      @page1_2.title = "Page 1 2"
      @page2_1 = ::Page.new(:slug => "page2-1")
      @page2_1.title = "Page 2 1"
      @page3_1 = ::Page.new(:slug => "page3-1")
      @page3_1.title = "Page 3 1"
      @page3_2 = ::Page.new(:slug => "page3-2")
      @page3_2.title = "Page 3 2"
      @page3_2.uid = "page3_2"

      @root.subpages << @page1_1
      @root.subpages << @page1_2
      @page1_1.subpages << @page2_1
      @page2_1.subpages << @page3_1
      @page2_1.subpages << @page3_2
      @root.save.reload
      @page1_1.save.reload
      @page1_2.save.reload
      @page2_1.save.reload
      @page3_1.save.reload
      @page3_2.save.reload
    end
    # describe "site instance" do
    #   it "be unique" do
    #     i = Site.instance
    #     j = Site.instance
    #     i.must_equal j
    #     Site.count.must_equal 1
    #   end
    # it "be a singleton within a site cache" do
    #   o = nil
    #   Site.with_cache do
    #     i = Site.instance
    #     j = Site.instance
    #     i.object_id.must_equal j.object_id
    #     o = i.object_id
    #   end
    #   i = Site.instance
    #   i.object_id.should_not == o
    # end

    # end
    describe 'mapping' do
      it "include the necessary details in the map" do
        @page3_2.map_entry.must_equal({
          :id => @page3_2.id,
          :title => "Page 3 2",
          :path => '/page1-1/page2-1/page3-2',
          :slug => 'page3-2',
          :type => 'Page',
          :type_id => ::Page.schema_id,
          :depth => 3,
          :private => false,
          :children => {},
          :ancestors => [
            { :id => @root.id, :title => "Homepage", :path => '/', :slug => '', :type => 'Page', :type_id => ::Page.schema_id, :depth => 0, :children => 2, :private => false},
            { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :slug => 'page1-1', :type => 'Page', :type_id => ::Page.schema_id, :depth => 1, :children => 1, :private => false},
            { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :slug => 'page2-1', :type => 'Page', :type_id => ::Page.schema_id, :depth => 2, :children => 2, :private => false}
          ],
          :generation => { "Subpages" => [
            { :id => @page3_1.id, :title => "Page 3 1", :path => '/page1-1/page2-1/page3-1', :slug => 'page3-1', :type => 'Page', :type_id => ::Page.schema_id, :depth => 3, :children => 0, :private => false},
            { :id => @page3_2.id, :title => "Page 3 2", :path => '/page1-1/page2-1/page3-2', :slug => 'page3-2', :type => 'Page', :type_id => ::Page.schema_id, :depth => 3, :children => 0, :private => false}
          ] }
        })

        @page2_1.map_entry.must_equal({
          :id => @page2_1.id,
          :title => "Page 2 1",
          :path => '/page1-1/page2-1',
          :slug => 'page2-1',
          :type => 'Page',
          :type_id => ::Page.schema_id,
          :depth => 2,
          :private => false,
          :children => {
            "Subpages" => [
              {:depth=>3,
               :type=>"Page",
               :type_id => ::Page.schema_id,
               :children=>0,
               :private => false,
               :path=>"/page1-1/page2-1/page3-1",
               :slug => 'page3-1',
               :title=>"Page 3 1",
               :id=>@page3_1.id},
               {:depth=>3,
                :type=>"Page",
                :type_id => ::Page.schema_id,
                :children=>0,
                :private => false,
                :path=>"/page1-1/page2-1/page3-2",
                :slug => 'page3-2',
                :title=>"Page 3 2",
                :id=>@page3_2.id}]},
                :ancestors => [
                  { :id => @root.id, :title => "Homepage", :path => '/', :slug => '',:type => 'Page', :type_id => ::Page.schema_id, :depth => 0, :children => 2, :private => false },
                  { :id => @page1_1.id, :title => "Page 1 1", :path => '/page1-1', :slug => 'page1-1',:type => 'Page', :type_id => ::Page.schema_id, :depth => 1, :children => 1, :private => false}
                ],
                :generation => {"Subpages" => [
                  { :id => @page2_1.id, :title => "Page 2 1", :path => '/page1-1/page2-1', :slug => 'page2-1',:type => 'Page', :type_id => ::Page.schema_id, :depth => 2, :children => 2, :private => false}
                ]}
        })
      end

      it "returns the private status of a page in the map" do
        page = Page.create_root("#private")
        page.map_entry[:private].must_equal true
      end


      it "retrieve details of the root by default" do
        @site.map.must_equal Page.root.map_entry
      end

      it "retrieve the details of the children of any page" do
        @site.map(@root.id).must_equal Page.root.map_entry
        @site.map(@page3_2.id).must_equal @page3_2.map_entry
      end
    end

    describe "page retrieval" do
      it "finds the root" do
        @site.home.must_equal @root
      end

      it "returns all roots" do
        hidden = Page.create slug: "hidden"
        roots = @site.roots
        roots["public"].must_equal "spontaneous.io"
        roots["roots"].keys.must_equal ["spontaneous.io", "#hidden"]
      end

      it "returns an empty roots object if no root exists" do
        @root.destroy
        roots = @site.roots
        roots['roots'].must_equal({})
      end

      it "finds ids" do
        @page3_2.reload
        [@page3_2.id, @page3_2.id.to_s].each do |id|
          @site[id].must_equal @page3_2
        end
      end

      it "work with paths" do
        @site['/page1-1/page2-1'].must_equal @page2_1.reload
      end

      it "work with UIDs" do
        @site["page3_2"].must_equal @page3_2.reload
        @site["$page3_2"].must_equal @page3_2.reload
      end

      it "maps symbols to UIDs" do
        @site[:page3_2].must_equal @page3_2.reload
      end

      it "finds hidden roots" do
        root = Page.create slug: "hidden"
        @site["#hidden"].must_equal root.reload
        child = Page.create slug: "something"
        root.subpages << child
        root.save
        @site["#hidden/something"].must_equal child.reload
      end

      it "have a shortcut direct method on Site" do
        @site.page3_2.must_equal @page3_2.reload
      end

      it "return section pages in the right order" do
        @site.at_depth(0).must_equal @root
        @site.at_depth(:root).must_equal @root
        @site.at_depth(:home).must_equal @root
        @site.at_depth(1).must_equal [@page1_1, @page1_2]
        @site.at_depth(:section).must_equal [@page1_1, @page1_2]
      end
    end
  end

  describe "Structure modification times" do
    before do
      S::State.delete
      # remove microseconds from time value
      @now = Time.at(Time.now.to_i)
    end

    it "just return the current time if no modifications have been made" do
      now = @now + 12
      Timecop.travel(now) do
        assert_site_modified(now)
      end
    end

    it "be updated when a page is added" do
      now = @now + 24
      Timecop.travel(now) do
        root = ::Page.create
      end
      assert_site_modified(now)
    end

    it "be updated when a page's title changes" do
      root = ::Page.create
      now = @now + 98
      Timecop.travel(now) do
        root.update(:title => "Some Title")
      end
      assert_site_modified(now)
    end

    it "be updated when a page's slug changes" do
      root = ::Page.create
      now = @now + 98
      Timecop.travel(now) do
        root.update(:slug => "updated-slug")
      end
      assert_site_modified(now)
    end

    it "not be updated when a piece is added" do
      now1 = @now + 24
      root = nil
      Timecop.travel(now1) do
        root = ::Page.create
      end
      now2 = @now + 240
      Timecop.travel(now2) do
        root.subpages << Piece.create
      end
      assert_site_modified(now1)
    end

    it "be updated when a page is deleted" do
      now1 = @now + 24
      root = child = nil
      Timecop.travel(now1) do
        root = ::Page.create
      end
      now2 = @now + 48
      Timecop.travel(now2) do
        child = ::Page.new
        root.subpages << child
        root.save
      end
      assert_site_modified(now2)
      now3 = @now + 128
      Timecop.travel(now3) do
        child.destroy
      end
      assert_site_modified(now3)
    end

    it "not be updated when a piece is deleted" do
      now1 = @now + 24
      root = piece = nil
      Timecop.travel(now1) do
        root = ::Page.create
      end
      now2 = @now + 240
      Timecop.travel(now2) do
        piece = ::Piece.create
        root.subpages << piece
      end
      assert_site_modified(now1)
      now3 = @now + 480
      Timecop.travel(now3) do
        piece.reload.destroy
      end
      assert_site_modified(now1)
    end
  end

  describe "URLs" do
    it "use the site_domain config value" do
      @site.config.site_domain = "spontaneouscms.org"
      @site.public_url.must_equal "http://spontaneouscms.org/"
      @site.public_url("/").must_equal "http://spontaneouscms.org/"
      @site.public_url("/something").must_equal "http://spontaneouscms.org/something"
      @site.public_url("/something").must_equal "http://spontaneouscms.org/something"
    end
  end

  describe "Paths" do
    before do
      FileUtils.mkdir(@site.root / "templates")
      @template_dir1 = File.expand_path("../../fixtures/templates", __FILE__)
      @plugin_dir = File.expand_path("../../fixtures/plugins/schema_plugin", __FILE__)
      @site.paths[:templates] << "non-existant-dir"
      @site.paths[:templates] << @template_dir1

      plugin = @site.load_plugin @plugin_dir
      plugin.init!
      plugin.load!
    end

    it "include all facet paths for a particular path group" do
      dirs = [@site.root / "templates", @template_dir1, @plugin_dir / "templates"]
      @site.paths(:templates).must_equal dirs
    end
  end
end
