# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

# Store.new(backend_class, options) #=> Store
# Store#revision(revision_number)   #=> Revision
# Store#revisions #=> [Fixnum]
# Revision#static_template(output) #=> (String or nil)
# Revision#dynamic_template(output, request_method = "GET") #=> (String or nil)
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

describe "Output store" do
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

  describe "File" do
    let(:root)  { Dir.mktmpdir }
    let(:store) { Spontaneous::Output::Store::File.new(root) }
    let(:revision) { 100 }
    let(:revision_path) { ::File.join(root, "00100") }


    it "puts static files under 'static'" do
      store.store_static(revision, "/one.html", "*template*")
      ::File.read(::File.join(revision_path, 'static', 'one.html')).must_equal "*template*"
    end

    it "puts protected files under 'protected'" do
      store.store_protected(revision, "/one.html", "*template*")
      ::File.read(::File.join(revision_path, 'protected', 'one.html')).must_equal "*template*"
    end

    it "puts dynamic files under 'dynamic'" do
      store.store_dynamic(revision, "/one.html", "*template*")
      ::File.read(::File.join(revision_path, 'dynamic', 'one.html')).must_equal "*template*"
    end

    it "puts private roots in files starting with '#'" do
      store.store_static(revision, "#one.html", "*template*")
      ::File.read(::File.join(revision_path, 'static', '#one.html')).must_equal "*template*"
    end

    it "puts private files in directories starting with '#'" do
      store.store_static(revision, "#private-tree/one.html", "*template*")
      ::File.read(::File.join(revision_path, 'static', '#private-tree', 'one.html')).must_equal "*template*"
    end

    it "puts asset files under 'assets'" do
      store.store_asset(revision, "/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css", "body{background:red;}")
      ::File.read(::File.join(revision_path, 'static', 'assets/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css')).must_equal "body{background:red;}"
    end

    it "supports any number of asset sub-directories" do
      store.store_asset(revision, "/css/modules/vendor/site-de4e312eb1deac7c937dc181b1ac8ab3.css", "body{background:red;}")
      ::File.read(::File.join(revision_path, 'static', 'assets/css/modules/vendor/site-de4e312eb1deac7c937dc181b1ac8ab3.css')).must_equal "body{background:red;}"
    end

    it "supports a custom asset prefix" do
      store = Spontaneous::Output::Store::File.new(root, assets_prefix: 'something')
      store.store_asset(revision, "/css/modules/vendor/site-de4e312eb1deac7c937dc181b1ac8ab3.css", "body{background:red;}")
      ::File.read(::File.join(revision_path, 'static', 'something/css/modules/vendor/site-de4e312eb1deac7c937dc181b1ac8ab3.css')).must_equal "body{background:red;}"
    end

    it "enables the retrieval of available revisions" do
      store.store_static(1, "/one.html", "*template*")
      store.store_protected(2, "/one.html", "*template*")
      store.store_dynamic(3, "/one.html", "*template*")
      store.revisions.must_equal [1, 2, 3]
    end

    it "enables the retrieval of templates" do
      store.store_static(revision, "/one.html", "*template*")
      store.load_static(revision, "/one.html").read.must_equal "*template*"
    end

    it "returns a File object for static templates" do
      store.store_static(revision, "/one.html", "*template*")
      result = store.load_static(revision, "/one.html")
      result.must_be_instance_of ::File
      result.to_path.must_equal ::File.join(revision_path, 'static', 'one.html')
      result.read.must_equal "*template*"
    end

    it "returns a File object for dynamic templates" do
      store.store_dynamic(revision, "/one.html", "*template*")
      result = store.load_dynamic(revision, "/one.html")
      result.must_be_instance_of ::File
      result.to_path.must_equal ::File.join(revision_path, 'dynamic', 'one.html')
      result.read.must_equal "*template*"
    end

    it "sets the returned template's encoding as UTF-8" do
      store.store_static(revision, "/one.html", "«küßî»")
      result = store.load_static(revision, "/one.html")
      result.external_encoding.must_equal Encoding::UTF_8
      result.read.must_equal "«küßî»"
    end

    it "returns nil when attempting to retrieve a non-existant template" do
      store.load_static(revision, "/faile.html").must_equal nil
    end

    it "puts all written keys into a transaction if given" do
      transaction = []
      store.store_static(revision, "/one.html", "*template*", transaction)
      store.store_protected(revision, "/one.html", "*template*", transaction)
      store.store_dynamic(revision, "/one.html", "*template*", transaction)
      store.store_asset(revision, "/css/site.css", "body{}", transaction)
      transaction.length.must_equal 4
      transaction.must_equal ["00100/static/one.html", "00100/protected/one.html", "00100/dynamic/one.html", "00100/static/assets/css/site.css"]
    end

    it "enables registration of a revision" do
      store.add_revision(100, ["100/one.html", "100/two.html", "100/three.html"])
      store.add_revision(101, ["101/one.html", "101/two.html", "101/three.html"])
      store.revisions.must_equal [100, 101]
    end

    it "prevents duplicate revisions in the revision list" do
      store.add_revision(100, ["100/one.html", "100/two.html", "100/three.html"])
      store.add_revision(101, ["101/one.html", "101/two.html", "101/three.html"])
      store.add_revision(100, ["100/one.html", "100/two.html", "100/three.html"])
      store.revisions.must_equal [100, 101]
    end

    it "symlinks the revision path when the revision is activated" do
      current = ::File.join(root, 'current')
      refute ::File.exist?(current)
      store.store_static(100, "/one.html", "*template*")
      store.activate_revision(100)
      assert ::File.exist?(current)
      assert ::File.symlink?(current)
      Pathname.new(current).realpath.to_s.must_equal Pathname.new(revision_path).realpath.to_s
    end

    it "writes the current revision into REVISION when the revision is activated" do
      revision_path = ::File.join(root, 'REVISION')
      refute ::File.exist?(revision_path)
      store.store_static(100, "/one.html", "*template*")
      store.activate_revision(100)
      assert ::File.exist?(revision_path)
      ::File.read(revision_path).must_equal Spontaneous::Paths.pad_revision_number(100)
    end

    it "returns a current revision of nil if none has been activated" do
      store.current_revision.must_equal nil
    end

    it "allows us to retrieve the current active revision" do
      store.store_static(100, "/one.html", "*template*")
      store.activate_revision(100)
      store.current_revision.must_equal 100
    end

    it "deletes the active revision if passed a value of nil" do
      current = ::File.join(root, 'current')
      revision_path = ::File.join(root, 'REVISION')
      store.store_static(100, "/one.html", "*template*")
      store.activate_revision(100)
      assert ::File.exist?(current)
      assert ::File.exist?(revision_path)

      store.activate_revision(nil)
      store.current_revision.must_equal nil
      refute ::File.exist?(current)
      refute ::File.exist?(revision_path)
    end

    it "allows for the deletion of a revision" do
      store.store_static(100, "/one.html", "*template*")
      store.store_static(100, "/another/two.html", "*template*")
      ::File.exist?(::File.join(revision_path, 'static', 'one.html')).must_equal true
      ::File.exist?(::File.join(revision_path, 'static', 'another/two.html')).must_equal true
      store.delete_revision(100)
      ::File.exist?(revision_path).must_equal false
    end
  end

  describe "Moneta" do
    let(:store) { Spontaneous::Output::Store::Moneta.new(:Memory) }
    let(:r) { 100 }
    let(:revision) { Spontaneous::Output::Store::Revision.new(r, store) }
    let(:transaction) { revision.transaction }


    it "allows the storage & retrieval of static templates" do
      store.store_static(r, "/one.html", "*template*")
      result = store.load_static(r, "/one.html")
      result.respond_to?(:read).must_equal true
      result.read.must_equal "*template*"
      result.respond_to?(:path).must_equal true
      result.respond_to?(:to_path).must_equal false
      result.path.must_equal "/#{r}/static/one.html"
    end

    it "allows the storage & retrieval of protected templates" do
      store.store_protected(r, "/one.html", "*template*")
      result = store.load_protected(r, "/one.html")
      result.respond_to?(:read).must_equal true
      result.read.must_equal "*template*"
      result.respond_to?(:path).must_equal true
      result.respond_to?(:to_path).must_equal false
      result.path.must_equal "/#{r}/protected/one.html"
    end

    it "allows the storage & retrieval of dynamic templates" do
      store.store_dynamic(r, "/one.html", "*template*")
      result = store.load_dynamic(r, "/one.html")
      result.respond_to?(:read).must_equal true
      result.read.must_equal "*template*"
      result.respond_to?(:path).must_equal true
      result.respond_to?(:to_path).must_equal false
      result.path.must_equal "/#{r}/dynamic/one.html"
    end

    it "allows the storage & retrieval of assets" do
      store.store_asset(r, "/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css", "body{color:red;}")
      result = store.load_static(r, "/assets/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css")
      result.respond_to?(:read).must_equal true
      result.read.must_equal "body{color:red;}"
      result.respond_to?(:path).must_equal true
      result.respond_to?(:to_path).must_equal false
      result.path.must_equal "/#{r}/static/assets/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css"
    end

    it "allows for the setting of a custom assets root path" do
      store = Spontaneous::Output::Store::Moneta.new(:Memory, assets_prefix: 'something')
      store.store_asset(r, "/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css", "body{color:red;}")
      result = store.load_static(r, "/something/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css")
      result.wont_equal nil
      result.read.must_equal "body{color:red;}"
    end

    it "puts all written keys into a transaction if given" do
      transaction = []
      store.store_static(r, "/one.html", "*template*", transaction)
      store.store_protected(r, "/two.html", "*template*", transaction)
      store.store_dynamic(r, "/three.html", "*template*", transaction)
      store.store_asset(r, "/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css", "body{color:red;}", transaction)
      transaction.length.must_equal 4
      transaction.must_equal ["100:static:/one.html", "100:protected:/two.html", "100:dynamic:/three.html", "100:static:/assets/css/site-de4e312eb1deac7c937dc181b1ac8ab3.css"]
    end

    it "enables registration of a revision" do
      store.add_revision(100, ["100:static:/one.html", "100:static:/two.html", "100:static:/three.html"])
      store.add_revision(101, ["101:static:/one.html", "101:static:/two.html", "101:static:/three.html"])
      store.revisions.must_equal [100, 101]
    end

    it "prevents duplicate revisions in the revision list" do
      store.add_revision(100, ["100/one.html", "100/two.html", "100/three.html"])
      store.add_revision(101, ["101/one.html", "101/two.html", "101/three.html"])
      store.add_revision(100, ["100/one.html", "100/two.html", "100/three.html"])
      store.revisions.must_equal [100, 101]
    end

    it "returns a current revision of nil if none has been activated" do
      store.current_revision.must_equal nil
    end

    it "allows us to retrieve the current active revision" do
      store.activate_revision(100)
      store.current_revision.must_equal 100
    end

    it "deletes the active revision if passed a value of nil" do
      store.activate_revision(nil)
      store.current_revision.must_equal nil
    end

    it "enables removal of a revision" do
      keys = []
      store.store_static(r, "/one.html", "*template*", keys)
      store.store_protected(r, "/two.html", "*template*", keys)
      store.store_dynamic(r, "/three.html", "*template*", keys)
      store.add_revision(100, keys)
      keys.each do |key|
        store.backend.key?(key).must_equal true
      end
      store.add_revision(101, ["101:static:/one.html", "101:protected:/two.html", "101:dynamic:/three.html"])
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

  describe "Transaction" do
    let(:store) { Spontaneous::Output::Store::Moneta.new(:Memory) }
    let(:r) { 100 }
    let(:transaction) { Spontaneous::Output::Store::Transaction.new(r, store) }
    let(:output_html) { page.output(:html) }
    let(:output_xml) { page.output(:xml) }
    let(:output_json) { page.output(:json) }

    it "tracks all keys written to it" do
      transaction.store(output_html, true, "*template*")
      transaction.store(output_xml, false, "*template*")
      transaction.store(output_json, false, "*template*")
      transaction.commit
      store.revisions.must_equal [ 100 ]
    end

    it "clears up the store after a rollback" do
      keys = ["100:static:/one.html"]
      transaction.store(output_html, false, "*template*")
      keys.each do |key|
        store.backend.key?(key).must_equal true
      end
      transaction.rollback
      store.revisions.must_equal []
      keys.each do |key|
        store.backend.key?(key).must_equal false
      end
    end

    it "ignores a rollback after a commit" do
      transaction.store(output_html, true, "*template*")
      transaction.store(output_xml, false, "*template*")
      transaction.store(output_json, false, "*template*")
      transaction.commit
      transaction.rollback
      store.revisions.must_equal [ 100 ]
    end

    it "writes to index.xxx when given the site root" do
      store.expects(:store_static).with(r, "/index.html", "*template*", transaction)
      transaction.store(home.output(:html), false, "*template*")
      store.expects(:store_dynamic).with(r, "/index.xml.php", "*template*", transaction)
      transaction.store(home.output(:xml), false, "*template*")
    end

    describe "template partitioning" do
      it "writes dynamic templates to dynamic partition" do
        store.expects(:store_dynamic).with(r, "/one.html.cut", "*template*", transaction)
        transaction.store(output_html, true, "*template*")
      end

      it "writes dynamic outputs to dynamic partition" do
        store.expects(:store_dynamic).with(r, "/one.xml.php", "*template*", transaction)
        transaction.store(output_xml, false, "*template*")
      end

      it "writes protected templates to protected partition" do
        page.expects(:dynamic?).returns(true)
        store.expects(:store_protected).with(r, "/one.html", "*template*", transaction)
        transaction.store(output_html, false, "*template*")
      end

      it "writes static templates to the static partition" do
        store.expects(:store_static).with(r, "/one.html", "*template*", transaction)
        transaction.store(output_html, false, "*template*")
      end
    end
  end

  describe "Revision" do
    let(:r) { 100 }
    let(:store) { Spontaneous::Output::Store::Moneta.new(:Memory) }
    let(:revision) { Spontaneous::Output::Store::Revision.new(r, store) }
    let(:output_html) { page.output(:html) }
    let(:output_xml) { page.output(:xml) }
    let(:output_json) { page.output(:json) }

    before do
      transaction = revision.transaction
      transaction.store(output_html, false, "HTML")
      transaction.store(output_xml, false, "XML")
      transaction.asset("/css/site.css", "CSS")
      transaction.commit
    end

    it "provides a transaction for writing" do
      revision.transaction.must_be_instance_of Spontaneous::Output::Store::Transaction
      revision.transaction.revision.must_equal r
    end

    it "allows for reading a static template" do
      template = revision.static_template(output_html)
      template.read.must_equal "HTML"
    end

    it "allows for reading a dynamic template" do
      template = revision.dynamic_template(output_xml)
      template.read.must_equal "XML"
    end

    it "doesn't return a dynamic template as a static one" do
      template = revision.static_template(output_xml)
      template.must_equal nil
    end

    it "allows for the activation of the revision" do
      store.expects(:activate_revision).with(r)
      revision.activate
    end

    it "allows for deletion of the revision" do
      store.expects(:delete_revision).with(r)
      revision.delete
    end
  end

  describe "Store" do
    let(:store) { Spontaneous::Output::Store.new(:Memory) }
    let(:output_html) { page.output(:html) }
    let(:output_xml) { page.output(:xml) }

    before do
      transaction = store.revision(20).transaction
      transaction.store(output_html, false, "HTML")
      transaction.store(output_xml, false, "XML")
      transaction.commit
    end

    it "will provide a revision instance" do
      store.revision(20).must_be_instance_of Spontaneous::Output::Store::Revision
      store.revision(20).revision.must_equal 20
    end

    it "can provide a list of revisions" do
      store.revisions.must_equal [20]
    end
  end
end
