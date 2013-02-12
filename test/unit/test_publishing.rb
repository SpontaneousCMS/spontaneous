# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)


class PublishingTest < MiniTest::Spec

  def self.site_root
    @site_root
  end

  def self.startup
    @site_root = Dir.mktmpdir
    template_source = File.expand_path(File.dirname(__FILE__) / "../fixtures/templates/publishing/templates")
    FileUtils.cp_r(template_source, @site_root)
  end

  def self.shutdown
    ::Content.delete_all_revisions! rescue nil
    teardown_site(true)
  end

  @@now = Time.now

  def setup
    @site = setup_site(self.class.site_root)
    @now = @@now
    Site.background_mode = :immediate
  end

  def teardown
    teardown_site(false)
  end

  context "publishing" do

    setup do
      stub_time(@@now)

      Content.delete

      class Page < ::Page
        field :title, :string, :default => "New Page"
        box :things
      end
      class Piece < ::Piece
        box :things
      end

      count = 0
      2.times do |i|
        c = Page.new(:uid => i)
        count += 1
        2.times do |j|
          d = Piece.new(:uid => "#{i}.#{j}")
          c.things << d
          count += 1
          2.times do |k|
            d.things << Page.new(:uid => "#{i}.#{j}.#{k}")
            d.save
            count += 1
          end
        end
        c.save
      end
    end

    teardown do
      PublishingTest.send(:remove_const, :Page) rescue nil
      PublishingTest.send(:remove_const, :Piece) rescue nil
      Content.delete
    end




    context "site publishing" do
      setup do
        Content.delete
        @revision = 3
        S::State.delete
        S::State.create(:revision => @revision, :published_revision => 2)
        S::State.revision.should == @revision
      end

      teardown do
        Content.delete_revision(@revision)
        S::Revision.delete
      end

      should "delete any conflicting revision tables" do
        S::Publishing::Revision.create(Content, 3)
        S::Site.publish_all
      end

      should "issue a publish_all if passed page id list including all pages (in any order)" do
        skip "Implement after scheduled publishes"
      end

      should "publish all" do
        Content.expects(:publish).with(@revision, nil)
        S::Site.publish_all
      end

      should "record date and time of publish" do
        Content.expects(:publish).with(@revision, nil)
        S::Revision.expects(:create).with(:revision => @revision, :published_at => @now)
        S::Site.publish_all
      end

      should "bump revision after a publish" do
        S::Site.publish_all
        S::Site.revision.should == @revision + 1
        S::Site.published_revision.should == @revision
      end

      should "not delete scheduled changes after an exception during publish" do
        skip "Implement after scheduled publishes"
      end

      should "set Site.pending_revision before publishing" do
        Content.expects(:publish).with(@revision, nil) { Site.pending_revision == @revision }
        Site.publish_all
      end

      should "reset Site.pending_revision after publishing" do
        Site.publish_all
        Site.pending_revision.should be_nil
      end

      should "not update first_published or last_published if rendering fails" do
        c = Content.create
        c.first_published_at.should be_nil
        Spontaneous::Site.expects(:pages).returns([c])
        # c.expects(:render).raises(Exception)
        begin
          silence_logger { Site.publish_all }
          # Site.publish_all
        rescue Exception; end
        c.reload
        Content.with_editable do
          c.first_published_at.should be_nil
        end
      end

      should "clean up state on publishing failure" do
        Site.pending_revision.should be_nil
        Content.revision_exists?(@revision).should be_false
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
        Site.pending_revision.should be_nil
        Content.revision_exists?(@revision).should be_false
        begin
          silence_logger { Site.publish_pages([change1]) }
        rescue Exception; end
        Site.pending_revision.should be_nil
        Content.revision_exists?(@revision).should be_false
      end
    end


    context "rendering" do
      setup do
        @revision = 2
        Content.delete_revision(@revision)
        Content.delete
        S::State.delete
        S::State.create(:revision => @revision, :published_revision => 2)
        S::Site.revision.should == @revision


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

      teardown do
        Content.delete_revision(@revision)
        Content.delete_revision(@revision+1)
        Content.delete
        S::State.delete
        Object.send(:remove_const, :PublishablePage) rescue nil
        Object.send(:remove_const, :DynamicPublishablePage) rescue nil
      end

      should "put its files into a numbered revision directory" do
        Spontaneous.revision_dir(2).should == Pathname.new(@site.root / 'cache/revisions' / "00002").realpath.to_s
      end

      should "symlink the latest revision to 'current'" do
        revision_dir = @site.revision_root / "00002"
        current_dir = @site.revision_root / "current"
        File.exists?(current_dir).should be_true
        File.symlink?(current_dir).should be_true
        File.readlink(current_dir).should == revision_dir
      end

      should "have access to the current revision within the templates" do
        revision_dir = @site.revision_root / "00002"
        File.read(revision_dir / "static/about.html").should == "Page: 'About' 2\n"
      end

      should "produce rendered versions of each page" do
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
          File.read(file).should == result
        end
        revision_dir = @site.revision_root / "00002"
        Dir[S.root / "public/**/*"].each do |public_file|
          site_file = public_file.gsub(%r(^#{S.root}/), '')
          publish_file = revision_dir / site_file
          File.exists?(publish_file).should be_true
        end
      end

      should "generate a config.ru file pointing to the current root" do
        config_file = @site.revision_root / "00002/config.ru"
        File.exists?(config_file).should be_true
        File.read(config_file).should =~ %r(#{Spontaneous.root})
      end

      should "generate a REVISION file containing the published revision number" do
        rev_file = @site.revision_root / "REVISION"
        result = File.read(rev_file)
        result.should == Spontaneous::Media.pad_revision(@revision)
      end

      should "transparently support previously unknown formats by assuming a simple HTML like rendering model" do
        PublishablePage.add_output :rtf
        Content.delete_revision(@revision+1)
        Site.publish_all
        File.read("#{@site.revision_root}/00003/static/index.rtf").should == "RICH!\n"
      end

      should "respect a format's #dynamic? setting when deciding a rendered templates location" do
        PublishablePage.add_output :rtf, :dynamic => true
        Content.delete_revision(@revision+1)
        Site.publish_all
        File.read("#{@site.revision_root}/00003/dynamic/index.rtf.cut").should == "RICH!\n"
      end

      should "run the content revision cleanup task after the revision is live xxx" do
        Content.expects(:cleanup_revisions).with(@revision+1, 8)
        Site.publish_all
      end

      context "hooks & triggers" do
        setup do
        end

        should "after_publish hook should be fired after publish is complete" do
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
          Site.published_revision.should == @revision+1
        end

        should "abort publish if hook raises error" do
          published_revision = @revision+1
          Site.pending_revision.should be_nil
          Content.revision_exists?(published_revision).should be_false

          Site.after_publish do |revision|
            raise "Boom"
          end

          begin
            silence_logger { Site.publish_all }
          rescue Exception; end

          Site.pending_revision.should be_nil
          Site.published_revision.should == @revision
          Content.revision_exists?(published_revision).should be_false
          S::Revision.first(:revision => published_revision).should be_nil
          previous_root = Spontaneous.revision_dir(@revision)
          published_root = Spontaneous.revision_dir(published_revision)
          symlink = Pathname.new Spontaneous.revision_dir
          # JRuby's Pathname#realpath doesn't work properly
          # See: http://jira.codehaus.org/browse/JRUBY-6460
          #
          # This workaround tests that the symlink has been re-pointed
          #
          # File.read(symlink + "REVISION").realpath.to_s.should == Pathname.new(previous_root).realpath.to_s
          File.open(Pathname.new(previous_root) + "REVISION", "w") do |file|
            file.write(@revision)
          end
          File.read(symlink + "REVISION").should == @revision.to_s
        end
      end
    end
  end
end
