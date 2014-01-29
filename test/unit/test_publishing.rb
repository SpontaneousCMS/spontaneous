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
    @site.background_mode = :immediate
    @template_store = @site.template_store(:Memory)

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
      @site.publish_all
    end

    it "issue a publish_all if passed page id list including all pages (in any order)" do
      skip "Implement after scheduled publishes"
    end

    it "publish all" do
      Content.expects(:publish).with(@revision, nil)
      @site.publish_all
    end

    it "record date and time of publish" do
      Content.expects(:publish).with(@revision, nil)
      S::PublishedRevision.expects(:create).with(:revision => @revision, :published_at => @now)
      @site.publish_all
    end

    it "bump revision after a publish" do
      @site.publish_all
      @site.revision.must_equal @revision + 1
      @site.published_revision.must_equal @revision
    end

    it "not delete scheduled changes after an exception during publish" do
      skip "Implement after scheduled publishes"
    end

    it "set Site.pending_revision before publishing" do
      Content.expects(:publish).with(@revision, nil) { @site.pending_revision == @revision }
      @site.publish_all
    end

    it "reset Site.pending_revision after publishing" do
      @site.publish_all
      @site.pending_revision.must_be_nil
    end

    it "not update first_published or last_published if rendering fails" do
      c = Content.create
      c.first_published_at.must_be_nil
      @site.expects(:pages).returns([c])
      # c.expects(:render).raises(Exception)
      begin
        silence_logger { @site.publish_all }
      rescue Exception; end
      c.reload
      Content.with_editable do
        c.first_published_at.must_be_nil
      end
    end

    it "clean up state on publishing failure" do
      @site.pending_revision.must_be_nil
      refute Content.revision_exists?(@revision)
      # don't like peeking into implementation here but don't know how else
      # to simulate the right error
      root = Page.create()
      @site.expects(:pages).returns([root])
      output = root.output(:html)
      output.expects(:render_using).raises(Exception)
      root.expects(:outputs).at_least_once.returns([output])
      revision_store = @template_store.revision(@revision)
      @template_store.expects(:revision).with(@revision).at_least_once.returns(revision_store)
      transaction = []
      revision_store.expects(:delete)
      revision_store.expects(:transaction).returns(transaction)
      transaction.expects(:rollback)
      begin
        silence_logger { @site.publish_all }
      rescue Exception; end
      @site.pending_revision.must_be_nil
      @template_store.revisions.must_equal []
      refute Content.revision_exists?(@revision)
      begin
        silence_logger { @site.publish_pages([change1]) }
      rescue Exception; end
      @site.pending_revision.must_be_nil
      refute Content.revision_exists?(@revision)
    end

    it "resets the must_publish_all flag after a successful publish" do
      @site.must_publish_all!
      @site.publish_all
      @site.must_publish_all?.must_equal false
    end
  end


  describe "rendering" do
    before do
      @revision = 2
      Content.delete_revision(@revision)
      Content.delete
      S::State.delete
      S::State.create(:revision => @revision, :published_revision => 2)
      @site.revision.must_equal @revision


      class ::PublishablePage < Page; end
      class ::DynamicPublishablePage < Page; end
      PublishablePage.box :box1
      DynamicPublishablePage.box :box1
      PublishablePage.layout :"static"
      PublishablePage.layout :"dynamic"

      DynamicPublishablePage.layout :"static"
      DynamicPublishablePage.layout :"dynamic"

      DynamicPublishablePage.controller do
        get { show "/about" }
      end

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
      @site.publish_all
      @template_revision = @template_store.revision(2)
    end

    after do
      Content.delete_revision(@revision)
      Content.delete_revision(@revision+1)
      Content.delete
      S::State.delete
      Object.send(:remove_const, :PublishablePage) rescue nil
      Object.send(:remove_const, :DynamicPublishablePage) rescue nil
    end

    it "symlink the latest revision to 'current'" do
      revision_dir = @site.revision_root / "00002"
      current_dir = @site.revision_root / "current"
      assert File.exists?(current_dir)
      assert File.symlink?(current_dir)
      File.readlink(current_dir).must_equal revision_dir
    end

    it "have access to the current revision within the templates" do
      @template_revision.static_template(@about.output(:html)).read.must_equal "Page: 'About' 2\n"
    end

    it "produce rendered versions of each page" do
      revision_dir = @site.revision_root / "00002"
      file = result = expected = nil
      @pages.each do |page|
        output = page.output(:html)
        case page.slug
        when "" # root is a dynamic page with no request handler
          expected = "Page: '#{page.title}' {{Time.now.to_i}}\n"
          result = @template_revision.dynamic_template(output)
        when "news" # news produces a static template but has a request handler
          expected = "Page: 'News' 2\n"
          result = @template_revision.static_template(output)
        when "contact" # contact is both dynamic and has a request handler
          expected = "Page: 'Contact' {{Time.now.to_i}}\n"
          result = @template_revision.dynamic_template(output)
        else # the other pages are static
          expected = "Page: '#{page.title}' 2\n"
          result = @template_revision.static_template(output)
        end
        assert_equal expected, result.read
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
      @site.publish_all
      template_revision = @template_store.revision(@revision+1)
      render = template_revision.static_template(@home.output(:rtf))
      render.read.must_equal "RICH!\n"
    end

    it "respect a format's #dynamic? setting when deciding a rendered templates location" do
      PublishablePage.add_output :rtf, :dynamic => true
      Content.delete_revision(@revision+1)
      @site.publish_all
      @template_store.revision(@revision + 1).dynamic_template(@home.output(:rtf)).read.must_equal "RICH!\n"
    end

    it "run the content revision cleanup task after the revision is live" do
      Content.expects(:cleanup_revisions).with(@revision+1, 8)
      @site.publish_all
    end

    describe "hooks & triggers" do
      it "after_publish hook should be fired after publish is complete" do
        publish1 = mock
        publish1.expects(:finished).with(@revision+1)
        publish2 = mock
        publish2.expects(:finished)
        @site.after_publish do |revision|
          publish1.finished(revision)
        end
        @site.after_publish do
          publish2.finished
        end
        Content.delete_revision(@revision+1)
        @site.publish_all
        @site.published_revision.must_equal @revision+1
      end

      it "abort publish if hook raises error" do
        published_revision = @revision+1
        @site.pending_revision.must_be_nil
        refute Content.revision_exists?(published_revision)

        @site.after_publish do |revision|
          raise "Boom"
        end

        begin
          silence_logger { @site.publish_all }
        rescue Exception; end

        @site.pending_revision.must_be_nil
        @site.published_revision.must_equal @revision
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
