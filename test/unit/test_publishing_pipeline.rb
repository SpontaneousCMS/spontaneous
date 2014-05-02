# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Publishing Pipeline" do
  let(:now) { Time.now }
  let(:later) { now + 3600 }
  let(:site) { @site }

  start do
    @site_root = Dir.mktmpdir
    revision = 3
    let(:site_root) { @site_root }
    let(:revision) { revision }
    template_source = File.expand_path(File.dirname(__FILE__) / "../fixtures/templates/publishing/templates")
    FileUtils.cp_r(template_source, @site_root)

    S::State.delete
    S::State.create(revision: revision, published_revision: (revision - 1))
  end

  finish do
    FileUtils.rm_r(@site_root)
    Timecop.return
  end

  before do
    Timecop.freeze(now)
    @site = setup_site(site_root)
    @site.background_mode = :immediate
    @output_store = @site.output_store(:Memory)
    S::State.revision.must_equal revision

    class Page
      field :title, :string, :default => "New Page"
      box :things
      add_output :xml
      layout(:html) { "=${title}.html" }
      layout(:xml)  { "=${title}.xml" }
    end

    @pages = []
    @pages << [@root = Page.create(title: "*Root*"), "*Root*"]
    (0..3).inject(@root) do |parent, n|
      page = Page.create(title: "Page #{n}", slug: "page-#{n}")
      parent.things << page
      @pages << [page, page.title.value]
      page
    end
    @pages.each { |page, title| page.save }
    @site.model.publish_all(revision)
  end

  after do
    Content.delete
    teardown_site(false)
  end

  def call(pages = nil)
    step.call(@site, revision, pages)
  end

  describe "Progress" do
    let(:total_steps) { 150 }
    let(:progress) { progress_class.new }
    let(:duration) { 205.635 }
    let(:later) { now + duration } # 3m 25.635s

    before do
      progress.start(total_steps)
    end

    describe "Silent" do
      let(:progress_class) { Spontaneous::Publishing::Progress::Silent }

      it "starts at 0%" do
        progress.percentage.must_equal 0.0
      end

      it "calculates progress % for a 1 step" do
        progress.step
        progress.position.must_equal 1
        progress.percentage.must_equal 0.67
      end

      it "increases position by 1 for each step" do
        75.times { progress.step }
        progress.position.must_equal 75
        progress.percentage.must_equal 50.0
      end

      it "calculates progress % for an arbitrary step" do
        progress.step(15)
        progress.position.must_equal 15
        progress.percentage.must_equal 10.0
      end

      it "calculates duration correctly" do
        _ = progress # initialize the progress instance with time set to `now`
        Timecop.travel(later) do |time|
          progress.duration.round(1).must_equal duration.round(1)
        end
      end

      it "gives a readable version of the duration" do
        _ = progress # initialize the progress instance with time set to `now`
        Timecop.travel(later) do |time|
          progress.duration.to_s.must_equal "00h 03m 25.64s"
        end
      end

      it "gives a readable version of the duration" do
        _ = progress # initialize the progress instance with time set to `now`
        h = 3; m = 36; s = 53.862
        Timecop.travel(now + (h * 3600) + (m * 60) + s) do |time|
          progress.duration.to_s.must_equal "03h 36m 53.86s"
        end
      end
    end

    describe "Multi" do
      let(:progress_class) { Spontaneous::Publishing::Progress::Multi }
      let(:progress1) { mock.tap { |m| m.stubs(:start) } }
      let(:progress2) { mock.tap { |m| m.stubs(:start) } }
      let(:progress) { progress_class.new(progress1, progress2) }

      it "passes all calls to start onto the progress children" do
        progress1.expects(:start).with(99)
        progress2.expects(:start).with(99)
        progress.start(99)
      end

      it "passes all calls to log onto the progress children" do
        progress1.expects(:log).with("A message")
        progress2.expects(:log).with("A message")
        progress.log("A message")
      end

      it "passes all calls to step onto the progress children" do
        progress1.expects(:step).with(1, "")
        progress2.expects(:step).with(1, "")
        progress.step
      end

      it "passes all arguments to step onto the progress children" do
        progress1.expects(:step).with(23, "fish")
        progress2.expects(:step).with(23, "fish")
        progress.step(23, "fish")
      end
      it "passes calls to #stage onto the children" do
        progress1.expects(:stage).with("doing")
        progress2.expects(:stage).with("doing")
        progress.stage("doing")
      end
      it "passes calls to #error onto the children" do
        progress1.expects(:error).with("doing")
        progress2.expects(:error).with("doing")
        progress.error("doing")
      end
      it "passes calls to #done onto the children" do
        progress1.expects(:done)
        progress2.expects(:done)
        progress.done
      end
    end
  end

  def run_step(progress = Spontaneous::Publishing::Progress::Silent.new)
    # the overall publish coordinator will ensure that every step runs within the right scope
    @site.model.scope(revision, true) do
      step.call(@site, revision, nil, progress)
    end
  end

  describe "CreateRevisionDirectory" do
    let(:step) { Spontaneous::Publishing::Steps::CreateRevisionDirectory }
    let(:path) { @site.revision_dir(revision) }

    it "has the right shortcut name" do
      step.to_sym.must_equal :create_revision_directory
    end

    it "creates the revision directory" do
      refute File.exist?(path)
      run_step
      assert File.exist?(path)
    end

    it "creates a tmp dir for the revision" do
      refute File.exist?(path / "tmp")
      run_step
      assert File.exist?(path / "tmp")
    end

    it "returns a step count of 1" do
      step.count(@site, revision, nil).must_equal 1
    end

    it "updates the progress object" do
      progress = mock()
      progress.expects(:stage).with("creating revision directory")
      progress.expects(:step).with(1, instance_of(String)).once
      run_step(progress)
    end

    it "deletes the path on rollback" do
      instance = run_step
      instance.rollback
      refute File.exist?(path)
    end

    it "runs rollback after throwing an exception" do
      instance = mock
      step.expects(:new).returns(instance)
      instance.expects(:call).raises(Exception)
      instance.expects(:rollback)
      lambda{ run_step }.must_raise(Exception)
    end
  end

  describe "RenderRevision" do
    let(:step) { Spontaneous::Publishing::Steps::RenderRevision }

    it "has the right shortcut name" do
      step.to_sym.must_equal :render_revision
    end

    it "renders each page to the output store" do
      store = @output_store.revision(revision).store
      @pages.each do |page, title|
        page.outputs.each do |output|
          key = store.output_key(output, false)
          store.expects(:store_static).with(revision, key, "=#{title}.#{output.name}", instance_of(Spontaneous::Output::Store::Transaction))
        end
      end
      run_step
    end

    it "returns the correct number of steps" do
      @site.model.scope(revision, true) do
        step.count(@site, revision, nil).must_equal (@pages.length * 2)
      end
    end

    it "updates the progress object" do
      progress = mock()
      progress.expects(:stage).with("rendering")
      progress.expects(:step).with(1, instance_of(String)).times(@pages.length * 2)
      run_step(progress)
    end

    it "returns an instance from #call" do
      run_step.must_be_instance_of step
    end

    it "deletes the rendered files on rollback" do
      instance = run_step
      store = @output_store.revision(revision).store
      store.expects(:delete_revision).with(revision)
      instance.rollback
    end

    it "runs rollback after throwing an exception" do
      instance = mock
      step.expects(:new).returns(instance)
      instance.expects(:call).raises(Exception)
      instance.expects(:rollback)
      lambda{ run_step }.must_raise(Exception)
    end
  end

  describe "GenerateSearchIndexes" do
    let(:step) { Spontaneous::Publishing::Steps::GenerateSearchIndexes }
    let(:index_count) { 0 }

    before do
      index_count.times do |n|
        @site.index "index#{n}".to_sym do; end
      end
      @site.indexes.length.must_equal index_count
    end

    it "has the right shortcut name" do
      step.to_sym.must_equal :generate_search_indexes
    end

    it "returns the correct number of steps when there are no search indexes" do
      @site.model.scope(revision, true) do
        step.count(@site, revision, nil).must_equal 0
      end
    end

    it "doesn't set the progress stage" do
      progress = mock
      progress.expects(:stage).with("indexing").never
      run_step(progress)
    end

    it "doesn't attempt to add any pages to the index" do
      @site.expects(:indexer).with(revision).never
      run_step
    end

    describe "with indexes" do
      let(:index_count) { 2 }

      it "returns the correct number of steps" do
        @site.model.scope(revision, true) do
          step.count(@site, revision, nil).must_equal (@pages.length)
        end
      end

      it "sets the progress stage to 'indexing'" do
        progress = mock
        progress.stubs(:step)
        progress.expects(:stage).with("indexing").once
        run_step(progress)
      end

      it "adds every page to the index" do
        indexer = mock
        S::Search::CompoundIndexer.expects(:new).returns(indexer)
        indexer.stubs(:close)
        @site.model.scope(revision, true) do
          @site.pages.each do |page|
            indexer.expects(:<<).with(page)
          end
        end
        run_step
      end

      it "updates the progress object with each page" do
        progress = Spontaneous::Publishing::Progress::Silent.new
        progress.expects(:step).with(1, instance_of(String)).times(@pages.count)
        run_step(progress)
      end

      # we can (currently) delegate this to the removal of the whole revision dir
      # since the indexes are just on-disk. At the point where the search is able
      # to integrate with other search engines then we're gonna need/have an api
      # call to delete a revision
      it "deletes the indexes on rollback"

      it "runs rollback after throwing an exception" do
        instance = mock
        step.expects(:new).returns(instance)
        instance.expects(:call).raises(Exception)
        instance.expects(:rollback)
        lambda{ run_step }.must_raise(Exception)
      end
    end
  end

  describe "CopyStaticFiles" do
    let(:step) { Spontaneous::Publishing::Steps::CopyStaticFiles }
    let(:application_path) { Pathname.new(File.expand_path("../../fixtures/example_application", __FILE__)) }
    let(:fixtures_path) { application_path + "public" }
    let(:revision_root) { @site.revision_dir(revision) }

    def assert_static_files(namespace = nil)
      Dir["#{fixtures_path}/**/*"].each do |fixture|
        path = Pathname.new(fixture)
        relative = path.relative_path_from(fixtures_path).to_s
        revision_file = File.join([revision_root, "public", namespace, relative].compact)
        File.exist?(revision_file).must_equal true
      end
    end

    before do
      FileUtils.cp_r(fixtures_path, @site.root)
      File.exist?(@site.root / 'public/favicon.ico').must_equal true
    end

    it "has the right shortcut name" do
      step.to_sym.must_equal :copy_static_files
    end

    it "sets the progress stage to 'copying files'" do
      progress = mock
      progress.stubs(:step)
      progress.expects(:stage).with("copying files").once
      run_step(progress)
    end

    it "steps the progress once for each facet" do
      progress = mock
      progress.stubs(:stage)
      progress.expects(:step).with(1, instance_of(String)).once
      run_step(progress)
    end

    it "gives its step count as the number of facets" do
      step.count(@site, revision, nil).must_equal 1
    end

    it "copies files in the site's public dir" do
      run_step
      assert_static_files
    end

    it "deletes the copied files on rollback" do
      instance = run_step
      instance.rollback
      refute File.exist?(File.join(revision_root, "public"))
    end

    it "runs rollback after throwing an exception" do
      instance = mock
      step.expects(:new).returns(instance)
      instance.expects(:call).raises(Exception)
      instance.expects(:rollback)
      lambda{ run_step }.must_raise(Exception)
    end

    describe "facets" do
      before do
        @site.load_plugin(application_path)
      end

      it "copies plugin files under their namespace" do
        run_step
        assert_static_files
        assert_static_files('example_application')
      end

      it "gives its step count as the number of facets" do
        step.count(@site, revision, nil).must_equal 2
      end

      it "steps the progress once for each facet" do
        progress = mock
        progress.stubs(:stage)
        progress.expects(:step).with(1, instance_of(String)).times(2)
        run_step(progress)
      end
    end
  end

  describe "GenerateRackupFile" do
    let(:step) { Spontaneous::Publishing::Steps::GenerateRackupFile }
    let(:rackup_path) { @site.revision_dir(revision) / "config.ru" }

    it "has the right shortcut name" do
      step.to_sym.must_equal :generate_rackup_file
    end

    it "reports a step count of 1" do
      step.count(@site, revision, nil).must_equal 1
    end

    it "sets the stage to 'create server config'" do
      progress = mock
      progress.stubs(:step)
      progress.expects(:stage).with("create server config").once
      run_step(progress)
    end

    it "increments the progress step by 1" do
      progress = mock
      progress.stubs(:stage)
      progress.expects(:step).with(1, instance_of(String)).once
      run_step(progress)
    end

    it "deletes the file on rollback" do
      instance = run_step
      instance.rollback
      refute File.exist?(rackup_path)
    end

    it "runs rollback after throwing an exception" do
      instance = mock
      step.expects(:new).returns(instance)
      instance.expects(:call).raises(Exception)
      instance.expects(:rollback)
      lambda{ run_step }.must_raise(Exception)
    end

    describe "config.ru" do
      let(:config) { File.read(rackup_path) }

      before do
        run_step
      end

      it "creates a config.ru file in the root of the revision dir" do
        File.exist?(rackup_path).must_equal true
      end

      it "sets the revision number in the ENV" do
        config.must_match %r(ENV\["SPOT_REVISION"\] *= *"#{revision}")
      end
    end
  end

  describe "ActivateRevision" do
    let(:step) { Spontaneous::Publishing::Steps::ActivateRevision }

    it "has the right shortcut name" do
      step.to_sym.must_equal :activate_revision
    end

    it "reports a step count of 1" do
      step.count(@site, revision, nil).must_equal 2
    end

    it "sets the stage to 'activating revision'" do
      progress = mock
      progress.stubs(:step)
      progress.expects(:stage).with("activating revision").once
      run_step(progress)
    end

    it "increments the progress step by 2" do
      progress = mock
      progress.stubs(:stage)
      progress.expects(:step).with(1, instance_of(String)).times(2)
      run_step(progress)
    end

    # set the site :published_revision value to revision
    it "updates the site's published revision setting" do
      state = @site.state
      state.published_revision.must_equal 2
      state.revision.must_equal revision
      run_step
      state.reload
      state.published_revision.must_equal revision
      state.revision.must_equal revision + 1
    end

    it "rollback sets the site state back to how it was" do
      instance = run_step
      instance.rollback
      state = @site.state.reload
      state.published_revision.must_equal 2
      state.revision.must_equal revision
    end

    it "runs rollback after throwing an exception" do
      instance = mock
      step.expects(:new).returns(instance)
      instance.expects(:call).raises(Exception)
      instance.expects(:rollback)
      lambda{ run_step }.must_raise(Exception)
    end

    describe "with previous revision" do
      let(:previous_revision_dir) { @site.revision_dir(revision-1) }
      let(:new_revision_dir) { @site.revision_dir(revision) }

      before do
        FileUtils.mkdir_p(previous_revision_dir)
        FileUtils.mkdir_p(new_revision_dir)
        File.open(File.join(previous_revision_dir, 'REVISION'), 'w') { |file| file.write(revision-1) }
        File.open(File.join(new_revision_dir, 'REVISION'), 'w') { |file| file.write(revision) }
        FileUtils.ln_s(previous_revision_dir, @site.revision_dir)
      end

      it "symlinks the new revision to 'current'" do
        run_step
        File.read(File.join(@site.revision_dir, 'REVISION')).must_equal revision.to_s
      end

      it "rollback re-points the 'current' symlink to the previous directory" do
        instance = run_step
        instance.rollback
        File.read(File.join(@site.revision_dir, 'REVISION')).must_equal (revision - 1).to_s
      end
    end

    describe "without previous revision" do
      let(:new_revision_dir) { @site.revision_dir(revision) }

      before do
        FileUtils.mkdir_p(new_revision_dir)
        File.open(File.join(new_revision_dir, 'REVISION'), 'w') { |file| file.write(revision) }
      end

      it "symlinks the new revision to 'current'" do
        run_step
        File.read(File.join(@site.revision_dir, 'REVISION')).must_equal revision.to_s
      end

      it "rollback deletes the 'current' symlink" do
        instance = run_step
        instance.rollback
        File.exist?(@site.revision_dir).must_equal false
      end
    end

    # generate revision file (which triggers the server reload)
    # progress.done
    # site is published at this point -- user scripts can run
    # clean up the revisions table

    # within the coordinator?:
    # set site :pending_revision to nil
    # create PublishedRevision instance
  end

  describe "WriteRevisionFile" do
    let(:step) { Spontaneous::Publishing::Steps::WriteRevisionFile }
    let(:path) { @site.revision_root / "REVISION" }

    it "has the right shortcut name" do
      step.to_sym.must_equal :write_revision_file
    end

    it "reports a step count of 1" do
      step.count(@site, revision, nil).must_equal 1
    end

    it "sets the stage to 'writing revision file'" do
      progress = mock
      progress.stubs(:step)
      progress.expects(:stage).with("writing revision file").once
      run_step(progress)
    end

    it "increments the progress step by 1" do
      progress = mock
      progress.stubs(:stage)
      progress.expects(:step).with(1, instance_of(String)).once
      run_step(progress)
    end

    it "writes a REVISION file with the current revision dirname" do
      run_step
      assert File.exist?(path)
      r = File.read(path)
      r.must_equal "00003"
    end

    it "deletes the file on rollback if none existed" do
      instance = run_step
      instance.rollback
      refute File.exist?(path)
    end

    it "reverts the file on rollback" do
      File.open(path, 'w') { |file| file.write("PREVIOUS") }
      instance = run_step
      instance.rollback
      assert File.exist?(path)
      File.read(path).must_equal "PREVIOUS"
    end

    it "runs rollback after throwing an exception" do
      instance = mock
      step.expects(:new).returns(instance)
      instance.expects(:call).raises(Exception)
      instance.expects(:rollback)
      lambda{ run_step }.must_raise(Exception)
    end
  end

  describe "ArchiveOldRevisions" do
    let(:step) { Spontaneous::Publishing::Steps::ArchiveOldRevisions }

    it "has the right shortcut name" do
      step.to_sym.must_equal :archive_old_revisions
    end

    it "reports a step count of 1" do
      step.count(@site, revision, nil).must_equal 1
    end

    it "sets the stage to 'archiving old revisions'" do
      progress = mock
      progress.stubs(:step)
      progress.expects(:stage).with("archiving old revisions").once
      run_step(progress)
    end

    it "increments the progress step by 1" do
      progress = mock
      progress.stubs(:stage)
      progress.expects(:step).with(1).once
      run_step(progress)
    end

    it "calls the cleanup command" do
      @site.config.stubs(:keep_revisions).returns(12)
      @site.model.expects(:cleanup_revisions).with(revision, 12)
      run_step
    end
  end

  describe "Pipeline" do
    let(:steps) { [] }
    let(:progress) do
      mock.tap do |progress|
        [:start, :stage, :step, :done].each { |method| progress.stubs(method) }
      end
    end
    let(:pages) { @modified_pages }
    let(:failing_step) {
      mock.tap do |step|
        step.stubs(:count).returns(12)
        step.expects(:call).raises(Exception)
      end
    }

    def run_steps(steps = steps, progress = progress)
      Spontaneous::Publishing::Pipeline.new(steps).run(@site, revision, pages, progress)
    end

    def modify_some_pages
      @modified_pages = @pages[0..1].map { |page, _| page }
      @modified_pages.each { |page| page.update(title: "Changed!") }
    end

    before do
      modify_some_pages
    end

    it "runs every step" do
      steps = [mock, mock]
      steps.each do |step|
        step.stubs(:count).returns(10)
        step.expects(:call).with(site, revision, pages, progress)
      end
      run_steps(steps)
    end

    it "calculates the total step count & sets up the progress" do
      steps = [mock, mock]
      steps.each do |step|
        step.stubs(:call)
        step.expects(:count).with(site, revision, pages, progress).returns(12)
      end
      progress.expects(:start).with(24)
      run_steps(steps)
    end

    it "calls #rollback on all steps completed before exception" do
      steps = [mock, mock]
      steps.each do |step|
        step.expects(:call).returns(step)
        step.stubs(:count).returns(12)
        step.expects(:rollback)
      end
      steps << failing_step
      lambda {
        run_steps(steps)
      }.must_raise(Exception)
    end

    it "doesn't call rollback on a step that doesn't support it" do
      steps = [mock, mock]
      steps.each do |step|
        step.expects(:call).returns(step)
        step.stubs(:count).returns(12)
      end
      steps << failing_step
      lambda {
        run_steps(steps)
      }.must_raise(Exception)
    end

    it "doesn't call #count on steps that don't support it" do
      steps = [
        proc { |s, r, pa, pr| nil },
        proc { |s, r, pa, pr| nil }
      ]
      run_steps(steps)
    end
  end

  describe "Publish" do
    let(:steps) {
      [mock, mock].each do |step|
        step.stubs(:call).returns(step)
      end
    }
    let(:mprogress)   { Spontaneous::Publishing::Progress }
    let(:publish) { Spontaneous::Publishing::Publish.new(site, revision, steps) }

    def modify_some_pages
      @modified_pages = @pages[0..1].map { |page, _| page }
      Timecop.travel(later) do
        @modified_pages.each { |page| page.update(title: "Changed!") }
      end
      @modified_pages = @modified_pages.map { |page| Page[page.id] }
    end

    before do
      modify_some_pages
    end


    it "constructs a multi progress object with a logger & a simultaneous client" do
      mprogress::Multi.expects(:new).with(instance_of(mprogress::Log), instance_of(mprogress::Simultaneous)).returns(mprogress::Silent.new)
      publish.publish_all
    end

    it "publishes all if passed every page" do
      publish.expects(:publish_all)
      publish.publish_pages(@site.model::Page.all)
    end

    it "publishes all if passed a list of every modified page" do
      publish.expects(:publish_all)
      publish.publish_pages(@modified_pages)
    end

    it "publish_all creates the content revision" do
      @site.model.expects(:publish).with(revision, nil)
      publish.publish_all
    end

    it "publish_pages creates the content revision" do
      @site.model.expects(:publish).with(revision, [@modified_pages.first])
      publish.publish_pages([@modified_pages.first])
    end

    it "runs all steps" do
      pages_matcher = all_of(*@modified_pages.map { |page| PageMatcher.new(page)})
      steps.each do |step|
        step.expects(:call).with(site, revision, pages_matcher, instance_of(mprogress::Multi))
      end
      publish.publish_pages(@modified_pages)
    end

    it "sets the publishing timestamps" do
      page = Page.create(title: "New page", slug: "page-new")
      @root.things << page
      page.save
      page.first_published_at.must_equal nil
      publish.publish_pages([page])
      @site.model.with_editable do
        page.reload.first_published_at.must_equal now
      end
    end

    # Need a custom matcher because a simple #== doesn't work as the
    # test is running within the scope of our new revision
    class PageMatcher < Mocha::ParameterMatchers::Base
      def initialize(page)
        @page = page
      end

      def matches?(available_parameters)
        parameter = available_parameters.shift
        parameter.any? { |param| param.class == @page.class && param.id == @page.id }
      end
    end

    # badly worded. a "publish all" usually works with 'nil' as the modified
    # page list (bad decision I guess). The current core publish steps
    # don't actually use the list of pages that are being published
    # but it's not crazy to assume that custom steps might want to know exactly
    # which pages have been published (say if you want to send a tweet for new pages)
    # so a publish all should convert the nil used internally into a list of all
    # the modified pages for use by the steps
    it "passes the list of modified pages to the publish steps aaa" do
      pages_matcher = all_of(*@modified_pages.map { |page| PageMatcher.new(page)})
      steps.each do |step|
        step.expects(:call).with(site, revision, pages_matcher, instance_of(mprogress::Multi))
      end
      publish.publish_all
    end

    it "sets the site pending revision" do
      @site.expects(:pending_revision=).with(revision)
      @site.expects(:pending_revision=).with(nil)
      publish.publish_all
    end

    describe "on completion" do
      it "sets the pending revision to nil" do
        @site.expects(:pending_revision=).with(revision)
        @site.expects(:pending_revision=).with(nil)
        publish.publish_all
      end

      it "creates a new PublishedRevision entry" do
        S::PublishedRevision.expects(:create).with(all_of(has_entry(revision: revision), has_entry(published_at: instance_of(Time))))
        publish.publish_all
      end

      it "calls #done on the progress object" do
        publish.progress.expects(:done)
        publish.publish_all
      end

      it "resets the site's 'must_publish_all' flag" do
        @site.expects(:must_publish_all!).with(false)
        publish.publish_all
      end

      it "creates the revision" do
        publish.publish_all
        @site.model.database.tables.include?(@site.model.revision_table(revision)).must_equal true
      end
    end

    describe "on error" do
      let(:failing_step) {
        mock.tap do |step|
          step.stubs(:count).returns(12)
          step.expects(:call).raises(Exception)
        end
      }

      before do
        steps << failing_step
      end

      it "sets the pending revision to nil" do
        @site.expects(:pending_revision=).with(revision)
        @site.expects(:pending_revision=).with(nil)
        lambda {publish.publish_all }.must_raise(Exception)
      end

      it "doesn't create a new PublishedRevision entry" do
        lambda {publish.publish_all }.must_raise(Exception)
        r = S::PublishedRevision.filter(:revision => revision).first
        r.must_equal nil
      end

      it "deletes the revision" do
        lambda {publish.publish_all }.must_raise(Exception)
        @site.model.database.tables.include?(@site.model.revision_table(revision)).must_equal false
      end

      it "calls #error on the progress object" do
        publish.progress.expects(:error).with(instance_of(Exception))
        lambda {publish.publish_all }.must_raise(Exception)
      end

      it "doesn't set the publishing timestamps" do
        page = Page.create(title: "New page", slug: "page-new")
        @root.things << page
        page.save
        page.first_published_at.must_equal nil
        lambda {publish.publish_pages([page]) }.must_raise(Exception)
        @site.model.with_editable do
          page.reload.first_published_at.must_equal nil
        end
      end

    end
  end

  describe "Site" do
    class FakeStep; end
    let(:steps) {
      [FakeStep].map do |step|
        step.stubs(:call)
        step.stubs(:count).returns(10)
        step
      end
    }

    it "maps symbols to step classes" do
      @site.publish do
        run :create_revision_directory
      end
      @site.publish_steps.to_a.first.must_equal Spontaneous::Publishing::Steps::CreateRevisionDirectory
    end

    it "passes all configured steps onto the publish system" do
      steps.each do |step|
        step.expects(:call).with(site, revision, anything, anything)
      end
      @site.publish do
        run FakeStep
      end
      @site.publish_all
    end
  end
end
