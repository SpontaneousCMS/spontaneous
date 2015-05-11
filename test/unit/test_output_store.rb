# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)
require 'fog'

# Store.new(backend_class, options) #=> Store
# Store#revision(revision_number)   #=> Revision
# Store#revisions #=> [Fixnum]
# Revision#static_template(output) #=> (String or nil)
# Revision#dynamic_template(output, request_method = 'GET') #=> (String or nil)
# Revision#transaction #=> Transaction
# Revision#activate
# Revision#delete
# Transaction#write(output, template)
# Transaction#commit
# Transaction#rollback
# Backend#store_static(revision, key, template)
# Backend#store_protected(revision, key, template)
# Backend#store_dynamic(revision, key, template)
# Backend#load_static(revision, key) #=> String
# Backend#load_protected(revision, key) #=> String
# Backend#load_dynamic(revision, key) #=> String
# Backend#delete_revision(revision)
# Backend#revisions #=> [Fixnum]

describe 'Output store' do
  start do
    site = setup_site
    let(:site) { site  }

    class CustomPage < Page
      add_output :xml, dynamic: true, language: 'php'
      add_output :json
      box :stuff
    end

    home = CustomPage.create
    page = CustomPage.new(slug: 'one')
    home.stuff << page
    page.save
    home.save
    let(:home) { home }
    let(:page) { page }
  end

  finish do
    Content.delete
    Object.send(:remove_const, :CustomPage) rescue nil
    teardown_site
  end

  describe 'File' do
    let(:root)  { Dir.mktmpdir }
    let(:store) { Spontaneous::Output::Store::File.new(root: root) }
    let(:revision) { 100 }
    let(:revision_path) { ::File.join(root, '00100') }


    it "puts static files under 'static'" do
      store.store_static(revision, '/one.html', '*template*')
      ::File.read(::File.join(revision_path, 'static', 'one.html')).must_equal '*template*'
    end

    it "puts protected files under 'protected'" do
      store.store_protected(revision, '/one.html', '*template*')
      ::File.read(::File.join(revision_path, 'protected', 'one.html')).must_equal '*template*'
    end

    it "puts dynamic files under 'dynamic'" do
      store.store_dynamic(revision, '/one.html', '*template*')
      ::File.read(::File.join(revision_path, 'dynamic', 'one.html')).must_equal '*template*'
    end

    it "puts private roots in files starting with '#'" do
      store.store_static(revision, '#one.html', '*template*')
      ::File.read(::File.join(revision_path, 'static', '#one.html')).must_equal '*template*'
    end

    it "puts private files in directories starting with '#'" do
      store.store_static(revision, '#private-tree/one.html', '*template*')
      ::File.read(::File.join(revision_path, 'static', '#private-tree', 'one.html')).must_equal '*template*'
    end

    it "puts asset files under 'assets'" do
      store.store_asset(revision, '/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css', 'body{background:red;}')
      ::File.read(::File.join(revision_path, 'assets', 'css/site-de4e312eb1deac7c937dc181b1ac8ab3.css')).must_equal 'body{background:red;}'
    end

    it 'supports any number of asset sub-directories' do
      store.store_asset(revision, '/css/modules/vendor/site-de4e312eb1deac7c937dc181b1ac8ab3.css', 'body{background:red;}')
      ::File.read(::File.join(revision_path, 'assets', 'css/modules/vendor/site-de4e312eb1deac7c937dc181b1ac8ab3.css')).must_equal 'body{background:red;}'
    end

    it 'enables the retrieval of available revisions' do
      store.store_static(1, '/one.html', '*template*')
      store.store_protected(2, '/one.html', '*template*')
      store.store_dynamic(3, '/one.html', '*template*')
      store.revisions.must_equal [1, 2, 3]
    end

    it 'enables the retrieval of templates' do
      store.store_static(revision, '/one.html', '*template*')
      store.load_static(revision, '/one.html').read.must_equal '*template*'
    end

    it 'returns a File object for static templates' do
      store.store_static(revision, '/one.html', '*template*')
      result = store.load_static(revision, '/one.html')
      result.must_be_instance_of ::File
      result.to_path.must_equal ::File.join(revision_path, 'static', 'one.html')
      result.read.must_equal '*template*'
    end

    it 'returns a File object for dynamic templates' do
      store.store_dynamic(revision, '/one.html', '*template*')
      result = store.load_dynamic(revision, '/one.html')
      result.must_be_instance_of ::File
      result.to_path.must_equal ::File.join(revision_path, 'dynamic', 'one.html')
      result.read.must_equal '*template*'
    end

    it 'returns a File object for assets' do
      store.store_asset(revision, '/site.css', 'body{color:yellow}')
      result = store.load_asset(revision, '/site.css')
      result.must_be_instance_of ::File
      result.to_path.must_equal ::File.join(revision_path, 'assets', 'site.css')
      result.read.must_equal 'body{color:yellow}'
    end

    it 'sets the returned template\'s encoding as UTF-8' do
      store.store_static(revision, '/one.html', '«küßî»')
      result = store.load_static(revision, '/one.html')
      result.external_encoding.must_equal Encoding::UTF_8
      result.read.must_equal '«küßî»'
    end

    it 'returns nil when attempting to retrieve a non-existant template' do
      store.load_static(revision, '/faile.html').must_equal nil
    end

    it 'puts all written keys into a transaction if given' do
      transaction = []
      store.store_static(revision, '/one.html', '*template*', transaction)
      store.store_protected(revision, '/one.html', '*template*', transaction)
      store.store_dynamic(revision, '/one.html', '*template*', transaction)
      store.store_asset(revision, '/css/site.css', 'body{}', transaction)
      transaction.length.must_equal 4
      transaction.must_equal ['00100/static/one.html', '00100/protected/one.html', '00100/dynamic/one.html', '00100/assets/css/site.css']
    end

    it 'enables registration of a revision' do
      store.add_revision(100, ['100/one.html', '100/two.html', '100/three.html'])
      store.add_revision(101, ['101/one.html', '101/two.html', '101/three.html'])
      store.revisions.must_equal [100, 101]
    end

    it 'prevents duplicate revisions in the revision list' do
      store.add_revision(100, ['100/one.html', '100/two.html', '100/three.html'])
      store.add_revision(101, ['101/one.html', '101/two.html', '101/three.html'])
      store.add_revision(100, ['100/one.html', '100/two.html', '100/three.html'])
      store.revisions.must_equal [100, 101]
    end

    it 'symlinks the revision path when the revision is activated' do
      current = ::File.join(root, 'current')
      refute ::File.exist?(current)
      store.store_static(100, '/one.html', '*template*')
      store.activate_revision(100)
      assert ::File.exist?(current)
      assert ::File.symlink?(current)
      Pathname.new(current).realpath.to_s.must_equal Pathname.new(revision_path).realpath.to_s
    end

    it 'writes the current revision into REVISION when the revision is activated' do
      revision_path = ::File.join(root, 'REVISION')
      refute ::File.exist?(revision_path)
      store.store_static(100, '/one.html', '*template*')
      store.activate_revision(100)
      assert ::File.exist?(revision_path)
      ::File.read(revision_path).must_equal Spontaneous::Paths.pad_revision_number(100)
    end

    it 'returns a current revision of nil if none has been activated' do
      store.current_revision.must_equal nil
    end

    it 'allows us to retrieve the current active revision' do
      store.store_static(100, '/one.html', '*template*')
      store.activate_revision(100)
      store.current_revision.must_equal 100
    end

    it 'deletes the active revision if passed a value of nil' do
      current = ::File.join(root, 'current')
      revision_path = ::File.join(root, 'REVISION')
      store.store_static(100, '/one.html', '*template*')
      store.activate_revision(100)
      assert ::File.exist?(current)
      assert ::File.exist?(revision_path)

      store.activate_revision(nil)
      store.current_revision.must_equal nil
      refute ::File.exist?(current)
      refute ::File.exist?(revision_path)
    end

    it 'allows for the deletion of a revision' do
      store.store_static(100, '/one.html', '*template*')
      store.store_static(100, '/another/two.html', '*template*')
      ::File.exist?(::File.join(revision_path, 'static', 'one.html')).must_equal true
      ::File.exist?(::File.join(revision_path, 'static', 'another/two.html')).must_equal true
      store.delete_revision(100)
      ::File.exist?(revision_path).must_equal false
    end
  end

  describe 'Moneta' do
    let(:store) { Spontaneous::Output::Store::Moneta.new(adapter: :Memory) }
    let(:r) { 100 }
    let(:revision) { Spontaneous::Output::Store::Revision.new(r, store) }
    let(:transaction) { revision.transaction }


    it 'allows the storage & retrieval of static templates' do
      store.store_static(r, '/one.html', '*template*')
      result = store.load_static(r, '/one.html')
      result.respond_to?(:read).must_equal true
      result.read.must_equal '*template*'
      result.respond_to?(:path).must_equal false
      result.respond_to?(:to_path).must_equal false
    end

    it 'allows the storage & retrieval of protected templates' do
      store.store_protected(r, '/one.html', '*template*')
      result = store.load_protected(r, '/one.html')
      result.respond_to?(:read).must_equal true
      result.read.must_equal '*template*'
      result.respond_to?(:path).must_equal true
      result.respond_to?(:to_path).must_equal false
      result.path.must_equal "/#{r}/protected/one.html"
    end

    it 'allows the storage & retrieval of dynamic templates' do
      store.store_dynamic(r, '/one.html', '*template*')
      result = store.load_dynamic(r, '/one.html')
      result.respond_to?(:read).must_equal true
      result.read.must_equal '*template*'
      result.respond_to?(:path).must_equal true
      result.respond_to?(:to_path).must_equal false
      result.path.must_equal "/#{r}/dynamic/one.html"
    end

    it 'allows the storage & retrieval of assets' do
      store.store_asset(r, '/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css', 'body{color:red;}')
      result = store.load_asset(r, '/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css')
      result.respond_to?(:read).must_equal true
      result.read.must_equal 'body{color:red;}'
      result.respond_to?(:to_path).must_equal false
      result.respond_to?(:path).must_equal false
    end

    it 'allows the storage & retrieval of static files' do
      store.store_static(r, '/robots.txt', 'allow *')
      result = store.load_static(r, '/robots.txt')
      result.respond_to?(:read).must_equal true
      result.read.must_equal 'allow *'
      result.respond_to?(:to_path).must_equal false
      result.respond_to?(:path).must_equal false
    end

    it 'puts all written keys into a transaction if given' do
      transaction = []
      store.store_static(r, '/one.html', '*template*', transaction)
      store.store_protected(r, '/two.html', '*template*', transaction)
      store.store_dynamic(r, '/three.html', '*template*', transaction)
      store.store_asset(r, '/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css', 'body{color:red;}', transaction)
      transaction.length.must_equal 4
      transaction.must_equal ['100:static:/one.html', '100:protected:/two.html', '100:dynamic:/three.html', '100:assets:/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css']
    end

    it 'enables registration of a revision' do
      store.add_revision(100, ['100:static:/one.html', '100:static:/two.html', '100:static:/three.html'])
      store.add_revision(101, ['101:static:/one.html', '101:static:/two.html', '101:static:/three.html'])
      store.revisions.must_equal [100, 101]
    end

    it 'prevents duplicate revisions in the revision list' do
      store.add_revision(100, ['100/one.html', '100/two.html', '100/three.html'])
      store.add_revision(101, ['101/one.html', '101/two.html', '101/three.html'])
      store.add_revision(100, ['100/one.html', '100/two.html', '100/three.html'])
      store.revisions.must_equal [100, 101]
    end

    it 'returns a current revision of nil if none has been activated' do
      store.current_revision.must_equal nil
    end

    it 'allows us to retrieve the current active revision' do
      store.activate_revision(100)
      store.current_revision.must_equal 100
    end

    it 'deletes the active revision if passed a value of nil' do
      store.activate_revision(nil)
      store.current_revision.must_equal nil
    end

    it 'enables removal of a revision' do
      keys = []
      store.store_static(r, '/one.html', '*template*', keys)
      store.store_protected(r, '/two.html', '*template*', keys)
      store.store_dynamic(r, '/three.html', '*template*', keys)
      store.add_revision(100, keys)
      keys.each do |key|
        store.backend.key?(key).must_equal true
      end
      store.add_revision(101, ['101/static:/one.html', '101/protected:/two.html', '101/dynamic:/three.html'])
      store.revisions.must_equal [100, 101]
      store.delete_revision(100)
      store.revisions.must_equal [101]
      hash = store.backend.backend
      keys.each do |key|
        hash.key?(key).must_equal false
      end
      hash.key?(store.revision_key(100)).must_equal false
    end
  end

  describe 'Fog' do
    let(:bucket_name) { 'www.example.com' }
    let(:access_key_id) { 'ACCESS_KEY_ID' }
    let(:secret_access_key) { 'SECRET_ACCESS_KEY' }
    let(:fog_credentials) {
      {provider: "AWS",
       aws_secret_access_key: "SECRET_ACCESS_KEY",
       aws_access_key_id: "ACCESS_KEY_ID"}
    }
    let(:store_config) { {connection: fog_credentials, bucket: bucket_name} }
    let(:store) { Spontaneous::Output::Store::Fog.new(store_config) }
    let(:r) { 100 }
    let(:revision) { Spontaneous::Output::Store::Revision.new(r, store) }
    let(:transaction) { revision.transaction }

    let(:fog) { Fog::Storage.new(fog_credentials) }
    let(:bucket) { fog.directories.get(bucket_name) }
    let(:files) { bucket.files }

    before do
      Fog.mock!
      fog.directories.create(key: bucket_name)
    end

    after do
      Fog::Mock.reset
    end

    it 'checks the validity of the given access credentials by creating a file' do
      file = mock()
      file.expects(:destroy)
      files = mock()
      files.expects(:create).returns(file)
      bucket = store.send :bucket
      bucket.expects(:files).returns(files)
      store.start_revision(r)
    end

    it 'allows the storage of static templates' do
      store.store_static(r, '/one.html', '*template*')
      store.join
      keys = files.map { |f| f.key }
      keys.must_equal [':revision/00100/static:/one.html']
    end

    it 'allows the storage of dynamic templates' do
      store.store_dynamic(r, '/one.html', '*template*')
      store.store_dynamic(r, '/two.html', '*template*')
      store.join
      keys = files.map { |f| f.key }
      keys.must_equal [':revision/00100/dynamic:/one.html', ':revision/00100/dynamic:/two.html']
    end

    it 'allows the storage of protected templates' do
      store.store_protected(r, '/one.html', '*template*')
      store.store_protected(r, '/two.html', '*template*')
      store.join
      keys = files.map { |f| f.key }
      keys.must_equal [':revision/00100/protected:/one.html', ':revision/00100/protected:/two.html']
    end

    it 'allows the storage of protected templates' do
      store.store_protected(r, '/one.html', '*template*')
      store.store_protected(r, '/two.html', '*template*')
      store.join
      keys = files.map { |f| f.key }
      keys.must_equal [':revision/00100/protected:/one.html', ':revision/00100/protected:/two.html']
    end

    it 'allows the storage of assets' do
      store.store_asset(r, '/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css', 'body{color:red;}')
      store.join
      keys = files.map { |f| f.key }
      keys.must_equal [':revision/00100/assets:/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css']
    end

    it 'allows the storage of static files' do
      store.store_static(r, '/robots.txt', 'allow *')
      store.join
      keys = files.map { |f| f.key }
      keys.must_equal [':revision/00100/static:/robots.txt']
    end

    it 'puts all written keys into a transaction if given' do
      transaction = []
      store.store_static(r, '/one.html', '*template*', transaction)
      store.store_protected(r, '/two.html', '*template*', transaction)
      store.store_dynamic(r, '/three.html', '*template*', transaction)
      store.store_asset(r, '/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css', 'body{color:red;}', transaction)
      store.join
      transaction.length.must_equal 4
      transaction.must_equal([
                              ":revision/00100/static:/one.html",
                              ":revision/00100/protected:/two.html",
                              ":revision/00100/dynamic:/three.html",
                              ":revision/00100/assets:/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css"
                             ])
    end

    it 'enables registration of a revision' do
      store.add_revision(100, [":revision/00100/static:/one.html", ":revision/00100/protected:/two.html", ":revision/00100/dynamic:/three.html"])
      store.add_revision(101, [":revision/00101/static:/one.html", ":revision/00101/protected:/two.html", ":revision/00101/dynamic:/three.html"])
      store.revisions.must_equal [100, 101]
    end

    it 'enables the retrieval of all keys for a revision' do
      store.add_revision(100, [":revision/00100/static:/one.html", ":revision/00100/protected:/two.html", ":revision/00100/dynamic:/three.html"])
      store.revision(100).must_equal [':revision/00100/static:/one.html', ':revision/00100/protected:/two.html', ':revision/00100/dynamic:/three.html']
    end

    it 'prevents duplicate revisions in the revision list' do
      store.add_revision(100, [":revision/00100/static:/one.html", ":revision/00100/protected:/two.html", ":revision/00100/dynamic:/three.html"])
      store.add_revision(101, [":revision/00101/static:/one.html", ":revision/00101/protected:/two.html", ":revision/00101/dynamic:/three.html"])
      store.add_revision(100, [":revision/00100/static:/one.html", ":revision/00100/protected:/two.html", ":revision/00100/dynamic:/three.html"])
      store.revisions.must_equal [100, 101]
    end

    it 'returns a current revision of nil if none has been activated' do
      store.current_revision.must_equal nil
    end

    it 'allows us to retrieve the current active revision' do
      store.activate_revision(100)
      store.current_revision.must_equal 100
    end

    it 'deletes the active revision if passed a value of nil' do
      store.activate_revision(nil)
      store.current_revision.must_equal nil
    end

    it 'enables removal of a revision' do
      keys = []
      store.store_static(r, '/one.html', '*template*', keys)
      store.store_protected(r, '/two.html', '*template*', keys)
      store.store_dynamic(r, '/three.html', '*template*', keys)
      store.add_revision(100, keys)
      store.add_revision(101, [":revision/00101/static:/one.html", ":revision/00101/protected:/two.html", ":revision/00101/dynamic:/three.html"])
      store.revisions.must_equal [100, 101]
      keys = store.revision(100)
      store.delete_revision(100)
      store.revisions.must_equal [101]
      keys.each do |key|
        files.get(key).must_equal nil
      end
      store.revision(100).must_equal nil
    end

    describe 'activation' do
      def store_and_activate(static = [], asset = [], protected = [], dynamic = [])
        keys = []
        static.each do |f|
          store.store_static(r, f, "static #{f}", keys)
        end
        asset.each do |f|
          store.store_asset(r, f, "asset #{f}", keys)
        end
        protected.each do |f|
          store.store_protected(r, f, "protected #{f}", keys)
        end
        dynamic.each do |f|
          store.store_dynamic(r, f, "dynamic #{f}", keys)
        end
        store.add_revision(r, keys)
        store.activate_revision(r)
      end

      it 'activates the homepage as /index.html' do
        store_and_activate(['/'])
        files.get('index.html').wont_equal nil
      end

      it 'activates the revision by copying the static files to the top-level namespace' do
        store_and_activate(['/one.html'], ['/css/site.css'])
        files.get('one').wont_equal nil
        files.get('assets/css/site.css').wont_equal nil
      end

      it 'only copies static & asset files to the root' do
        store_and_activate([], [], ['/protected.html'], ['/dynamic.erb'])
        files.get('protected').must_equal nil
        files.get('dynamic.erb').must_equal nil
      end

      it 'adds a far-future expiry to asset files' do
        store_and_activate([], ['/css/site.css'])
        css = files.get('assets/css/site.css')
        css.cache_control.must_equal 'public, max-age=31557600'
      end

      it 'adds a 1 minute expiry to static files' do
        store_and_activate(['/robots.txt'], [])
        file = files.get('robots.txt')
        file.cache_control.must_equal 'public, max-age=60'
      end

      it 'makes the files public' do
        store_and_activate(['/one.html'], ['/css/site.css'])
        ['one', 'assets/css/site.css'].each do |key|
          files.get(key).public?.must_equal true
        end
      end

      it 'sets a content type of text/html for files with a .html extension' do
        store_and_activate(['/one.html'])
        files.get('one').content_type.must_equal 'text/html;charset=utf-8'
      end
    end
  end

  describe 'Transaction' do
    let(:store) { Spontaneous::Output::Store::Moneta.new(adapter: :Memory) }
    let(:r) { 100 }
    let(:transaction) { Spontaneous::Output::Store::Transaction.new(r, store) }
    let(:output_html) { page.output(:html) }
    let(:output_xml) { page.output(:xml) }
    let(:output_json) { page.output(:json) }

    it 'calls start_revision on the backing store' do
      store.expects(:start_revision).with(r)
      transaction
    end

    it 'tracks all keys written to it' do
      transaction.store_output(output_html, true, '*template*')
      transaction.store_output(output_xml, false, '*template*')
      transaction.store_output(output_json, false, '*template*')
      transaction.commit
      store.revisions.must_equal [ 100 ]
    end

    it 'clears up the store after a rollback' do
      keys = ['100:static:/one.html']
      transaction.store_output(output_html, false, '*template*')
      keys.each do |key|
        store.backend.key?(key).must_equal true
      end
      transaction.rollback
      store.revisions.must_equal []
      keys.each do |key|
        store.backend.key?(key).must_equal false
      end
    end

    it 'ignores a rollback after a commit' do
      transaction.store_output(output_html, true, '*template*')
      transaction.store_output(output_xml, false, '*template*')
      transaction.store_output(output_json, false, '*template*')
      transaction.commit
      transaction.rollback
      store.revisions.must_equal [ 100 ]
    end

    it 'writes to index.xxx when given the site root' do
      store.expects(:store_static).with(r, '/index.html', '*template*', transaction)
      transaction.store_output(home.output(:html), false, '*template*')
      store.expects(:store_dynamic).with(r, '/index.xml.php', '*template*', transaction)
      transaction.store_output(home.output(:xml), false, '*template*')
    end

    describe 'template partitioning' do
      it 'writes dynamic templates to dynamic partition' do
        store.expects(:store_dynamic).with(r, '/one.html.cut', '*template*', transaction)
        transaction.store_output(output_html, true, '*template*')
      end

      it 'writes dynamic outputs to dynamic partition' do
        store.expects(:store_dynamic).with(r, '/one.xml.php', '*template*', transaction)
        transaction.store_output(output_xml, false, '*template*')
      end

      it 'writes protected templates to protected partition' do
        page.expects(:dynamic?).returns(true)
        store.expects(:store_protected).with(r, '/one.html', '*template*', transaction)
        transaction.store_output(output_html, false, '*template*')
      end

      it 'writes static templates to the static partition' do
        store.expects(:store_static).with(r, '/one.html', '*template*', transaction)
        transaction.store_output(output_html, false, '*template*')
      end

      it 'writes private formats to the protected partition' do
        output_html.expects(:private?).returns(true)
        store.expects(:store_protected).with(r, '/one.html', '*template*', transaction)
        transaction.store_output(output_html, false, '*template*')
      end

      it 'writes formats with custom mime types to the protected partition' do
        output_html.expects(:custom_mimetype?).returns(true)
        store.expects(:store_protected).with(r, '/one.html', '*template*', transaction)
        transaction.store_output(output_html, false, '*template*')
      end

      it 'writes pages in private roots to the protected partition' do
        output_html.page.expects(:in_private_tree?).returns(true)
        store.expects(:store_protected).with(r, '/one.html', '*template*', transaction)
        transaction.store_output(output_html, false, '*template*')
      end
    end
  end

  describe 'Revision' do
    let(:r) { 100 }
    let(:store) { Spontaneous::Output::Store::Moneta.new(adapter: :Memory) }
    let(:revision) { Spontaneous::Output::Store::Revision.new(r, store) }
    let(:output_html) { page.output(:html) }
    let(:output_json) { page.output(:json) }
    let(:output_xml) { page.output(:xml) }
    let(:output_json) { page.output(:json) }

    before do
      transaction = revision.transaction
      transaction.store_output(output_html, false, 'HTML')
      transaction.store_output(output_xml, false, 'XML')
      transaction.store_output(output_json, false, 'JSON')
      transaction.store_asset('/css/site.css', 'CSS')
      transaction.store_static('/robots.txt', 'allow *')
      transaction.commit
    end

    it 'provides a transaction for writing' do
      revision.transaction.must_be_instance_of Spontaneous::Output::Store::Transaction
      revision.transaction.revision.must_equal r
    end

    it 'allows for reading a static template' do
      template = revision.static_template(output_html)
      template.read.must_equal 'HTML'
    end

    it 'allows for reading a dynamic template' do
      template = revision.dynamic_template(output_xml)
      template.read.must_equal 'XML'
    end

    it 'allows for reading a static html template as a static file' do
      template = revision.static_file("#{page.path}.html")
      template.read.must_equal 'HTML'
    end

    it 'allows for reading a static json template as a static file' do
      template = revision.static_file("#{page.path}.json")
      template.read.must_equal 'JSON'
    end

    it 'allows for reading an asset file' do
      template = revision.static_asset('/css/site.css')
      template.read.must_equal 'CSS'
    end

    it 'allows for reading an static file' do
      template = revision.static_file('/robots.txt')
      template.read.must_equal 'allow *'
    end

    it "doesn't return a dynamic template as a static one" do
      template = revision.static_template(output_xml)
      template.must_equal nil
    end

    it 'allows for the activation of the revision' do
      store.expects(:activate_revision).with(r)
      revision.activate
    end

    it 'allows for deletion of the revision' do
      store.expects(:delete_revision).with(r)
      revision.delete
    end
  end

  describe 'Store' do
    let(:store) { Spontaneous::Output::Store.new(:Memory) }
    let(:output_html) { page.output(:html) }
    let(:output_xml) { page.output(:xml) }

    before do
      transaction = store.revision(20).transaction
      transaction.store_output(output_html, false, 'HTML')
      transaction.store_output(output_xml, false, 'XML')
      transaction.commit
    end

    it 'will provide a revision instance' do
      store.revision(20).must_be_instance_of Spontaneous::Output::Store::Revision
      store.revision(20).revision.must_equal 20
    end

    it 'can provide a list of revisions' do
      store.revisions.must_equal [20]
    end

    it 'maps File output stores to the right class' do
      store = Spontaneous::Output::Store.backing_class(:File)
      store.must_equal Spontaneous::Output::Store::File
    end
    it 'maps Fog output stores to the right class' do
      store = Spontaneous::Output::Store.backing_class(:Fog)
      store.must_equal Spontaneous::Output::Store::Fog
    end
    it 'maps Memcache output stores to the right class' do
      store = Spontaneous::Output::Store.backing_class(:Memcached)
      store.must_equal Spontaneous::Output::Store::Moneta
    end
    it 'maps Redis output stores to the right class' do
      store = Spontaneous::Output::Store.backing_class(:Redis)
      store.must_equal Spontaneous::Output::Store::Moneta
    end
  end
end
