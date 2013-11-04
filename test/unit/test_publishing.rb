# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Publishing" do

  start do
    site_root = Dir.mktmpdir
    template_source = File.expand_path(File.dirname(__FILE__) / "../fixtures/templates/publishing/templates")
    FileUtils.cp_r(template_source, site_root)
    let(:site_root) { site_root }
  end

  finish do
    ::Content.delete_all_revisions! rescue nil
    teardown_site(true)
  end

  before do
    @now = Time.now
    stub_time(@now)

    @site = setup_site(site_root)
    Site.background_mode = :immediate

    Content.delete

    class Page
      field :title, :string, :default => "New Page"
      box :things
    end
    class Piece
      box :things
    end
  end

  after do
    Object.send(:remove_const, :Page) rescue nil
    Object.send(:remove_const, :Piece) rescue nil
    Content.delete
    teardown_site(false)
  end

  describe "site publishing" do
    before do
      Content.delete
      @revision = 3
      S::State.delete
      S::State.create(:revision => @revision, :published_revision => 2)
      S::State.revision.must_equal @revision
    end

    after do
      Content.delete_revision(@revision)
      S::PublishedRevision.delete
    end

    it "delete any conflicting revision tables" do
      S::Publishing::Revision.create(Content, 3)
      S::Site.publish_all
    end

    it "issue a publish_all if passed page id list including all pages (in any order)" do
      skip "Implement after scheduled publishes"
    end

    it "publish all" do
      Content.expects(:publish).with(@revision, nil)
      S::Site.publish_all
    end

    it "record date and time of publish" do
      Content.expects(:publish).with(@revision, nil)
      S::PublishedRevision.expects(:create).with(:revision => @revision, :published_at => @now)
      S::Site.publish_all
    end

    it "bump revision after a publish" do
      S::Site.publish_all
      S::Site.revision.must_equal @revision + 1
      S::Site.published_revision.must_equal @revision
    end

    it "not delete scheduled changes after an exception during publish" do
      skip "Implement after scheduled publishes"
    end

    it "set Site.pending_revision before publishing" do
      Content.expects(:publish).with(@revision, nil) { Site.pending_revision == @revision }
      Site.publish_all
    end

    it "reset Site.pending_revision after publishing" do
      Site.publish_all
      Site.pending_revision.must_be_nil
    end

    it "not update first_published or last_published if rendering fails" do
      c = Content.create
      c.first_published_at.must_be_nil
      Spontaneous::Site.expects(:pages).returns([c])
      # c.expects(:render).raises(Exception)
      begin
        silence_logger { Site.publish_all }
        # Site.publish_all
      rescue Exception; end
      c.reload
      Content.with_editable do
        c.first_published_at.must_be_nil
      end
    end

    it "clean up state on publishing failure" do
      Site.pending_revision.must_be_nil
      refute Content.revision_exists?(@revision)
      # don't like peeking into implementation here but don't know how else
      # to simulate the right error
      root = Page.create()
      Spontaneous::Site.expects(:pages).returns([root])
      output = root.output(:html)
      output.expects(:render_using).raises(Exception)
      root.expects(:outputs).at_least_once.returns([output])
      begin
        silence_logger { Site.publish_all }
      rescue Exception; end
      Site.pending_revision.must_be_nil
      refute Content.revision_exists?(@revision)
      begin
        silence_logger { Site.publish_pages([change1]) }
      rescue Exception; end
      Site.pending_revision.must_be_nil
      refute Content.revision_exists?(@revision)
    end

    it "resets the must_publish_all flag after a successful publish" do
      Site.must_publish_all!
      Site.publish_all
      Site.must_publish_all?.must_equal false
    end
  end


  describe "rendering" do
    before do
      @revision = 2
      Content.delete_revision(@revision)
      Content.delete
      S::State.delete
      S::State.create(:revision => @revision, :published_revision => 2)
      S::Site.revision.must_equal @revision


      class ::PublishablePage < Page; end
      class ::DynamicPublishablePage < Page; end
      PublishablePage.box :box1
      DynamicPublishablePage.box :box1
      PublishablePage.layout :"static"
      PublishablePage.layout :"dynamic"

      DynamicPublishablePage.layout :"static"
      DynamicPublishablePage.layout :"dynamic"

      DynamicPublishablePage.request { show "/about" }

      @home = PublishablePage.create(:title => 'Home')
      @home.layout = :"dynamic"
      @about = PublishablePage.create(:title => "About", :slug => "about")
      @blog = PublishablePage.create(:title => "Blog", :slug => "blog")
      @post1 = PublishablePage.create(:title => "Post 1", :slug => "post-1")
      @post2 = PublishablePage.create(:title => "Post 2", :slug => "post-2")
      @post3 = PublishablePage.create(:title => "Post 3", :slug => "post-3")
      @news = DynamicPublishablePage.create(:title => "News", :slug => "news")
      @contact = DynamicPublishablePage.create(:title => "Contact", :slug => "contact")
      @contact.layout = :dynamic
      @home.box1 << @about
      @home.box1 << @blog
      @home.box1 << @news
      @home.box1 << @contact
      @blog.box1 << @post1
      @blog.box1 << @post2
      @blog.box1 << @post3
      @pages = [@home, @about, @blog, @news, @post1, @post2, @post3]
      @pages.each { |p| p.save }
      Site.publish_all
    end

    after do
      Content.delete_revision(@revision)
      Content.delete_revision(@revision+1)
      Content.delete
      S::State.delete
      Object.send(:remove_const, :PublishablePage) rescue nil
      Object.send(:remove_const, :DynamicPublishablePage) rescue nil
    end

    it "put its files into a numbered revision directory" do
      Spontaneous.revision_dir(2).must_equal Pathname.new(@site.root / 'cache/revisions' / "00002").realpath.to_s
    end

    it "symlink the latest revision to 'current'" do
      revision_dir = @site.revision_root / "00002"
      current_dir = @site.revision_root / "current"
      assert File.exists?(current_dir)
      assert File.symlink?(current_dir)
      File.readlink(current_dir).must_equal revision_dir
    end

    it "have access to the current revision within the templates" do
      revision_dir = @site.revision_root / "00002"
      File.read(revision_dir / "static/about.html").must_equal "Page: 'About' 2\n"
    end

    it "produce rendered versions of each page" do
      revision_dir = @site.revision_root / "00002"
      file = result = nil
      @pages.each do |page|
        case page.slug
        when "" # root is a dynamic page with no request handler
          file = revision_dir / "dynamic/index.html.cut"
          result = "Page: '#{page.title}' {{Time.now.to_i}}\n"
        when "news" # news produces a static template but has a request handler
          file = revision_dir / "protected/news.html"
          result = "Page: 'News' 2\n"
        when "contact" # contact is both dynamic and has a request handler
          file = revision_dir / "dynamic/contact.html.cut"
          result = "Page: 'Contact' {{Time.now.to_i}}\n"
        else # the other pages are static
          file = revision_dir / "static#{page.path}.html"
          result = "Page: '#{page.title}' 2\n"
        end
        assert File.exists?(file), "File '#{file}' should exist"
        File.read(file).must_equal result
      end
      revision_dir = @site.revision_root / "00002"
      Dir[S.root / "public/**/*"].each do |public_file|
        site_file = public_file.gsub(%r(^#{S.root}/), '')
        publish_file = revision_dir / site_file
        assert File.exists?(publish_file)
      end
    end

    it "generate a config.ru file pointing to the current root" do
      config_file = @site.revision_root / "00002/config.ru"
      assert File.exists?(config_file)
      File.read(config_file).must_match %r(#{Spontaneous.root})
    end

    it "generate a REVISION file containing the published revision number" do
      rev_file = @site.revision_root / "REVISION"
      result = File.read(rev_file)
      result.must_equal Spontaneous::Media.pad_revision(@revision)
    end

    it "transparently support previously unknown formats by assuming a simple HTML like rendering model" do
      PublishablePage.add_output :rtf
      Content.delete_revision(@revision+1)
      Site.publish_all
      File.read("#{@site.revision_root}/00003/static/index.rtf").must_equal "RICH!\n"
    end

    it "respect a format's #dynamic? setting when deciding a rendered templates location" do
      PublishablePage.add_output :rtf, :dynamic => true
      Content.delete_revision(@revision+1)
      Site.publish_all
      File.read("#{@site.revision_root}/00003/dynamic/index.rtf.cut").must_equal "RICH!\n"
    end

    it "run the content revision cleanup task after the revision is live" do
      Content.expects(:cleanup_revisions).with(@revision+1, 8)
      Site.publish_all
    end

    describe "hooks & triggers" do
      it "after_publish hook should be fired after publish is complete" do
        publish1 = mock
        publish1.expects(:finished).with(@revision+1)
        publish2 = mock
        publish2.expects(:finished)
        Site.after_publish do |revision|
          publish1.finished(revision)
        end
        Site.after_publish do
          publish2.finished
        end
        Content.delete_revision(@revision+1)
        Site.publish_all
        Site.published_revision.must_equal @revision+1
      end

      it "abort publish if hook raises error" do
        published_revision = @revision+1
        Site.pending_revision.must_be_nil
        refute Content.revision_exists?(published_revision)

        Site.after_publish do |revision|
          raise "Boom"
        end

        begin
          silence_logger { Site.publish_all }
        rescue Exception; end

        Site.pending_revision.must_be_nil
        Site.published_revision.must_equal @revision
        refute Content.revision_exists?(published_revision)
        S::PublishedRevision.first(:revision => published_revision).must_be_nil
        previous_root = Spontaneous.revision_dir(@revision)
        published_root = Spontaneous.revision_dir(published_revision)
        symlink = Pathname.new Spontaneous.revision_dir
        # JRuby's Pathname#realpath doesn't work properly
        # See: http://jira.codehaus.org/browse/JRUBY-6460
        #
        # This workaround tests that the symlink has been re-pointed
        #
        # File.read(symlink + "REVISION").realpath.to_s.must_equal Pathname.new(previous_root).realpath.to_s
        File.open(Pathname.new(previous_root) + "REVISION", "w") do |file|
          file.write(@revision)
        end
        File.read(symlink + "REVISION").must_equal @revision.to_s
      end
    end
  end
end
