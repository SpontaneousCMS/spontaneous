# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

describe "Singletons" do
  before do
    @site = setup_site
    class ::SingletonPage < ::Page
      group :singletons
      singleton :singleton, :malcom
    end
  end

  after do
    Object.send :remove_const, :SingletonPage rescue nil
    teardown_site
  end

  it "prevents creation of two instances of a singleton type" do
    a = SingletonPage.create
    b = nil
    proc {
      b = SingletonPage.create
    }.must_raise(Spontaneous::SingletonException)
    b.must_equal nil
    proc {
      b = SingletonPage.new
      b.save
    }.must_raise(Spontaneous::SingletonException)
    SingletonPage.count.must_equal 1
  end

  it "allows saving of existing singleton instances" do
    a = SingletonPage.create
    a.uid = "changed"
    a.save
  end

  it "::singleton?" do
    ::Piece.singleton?.must_equal false
    ::Page.singleton?.must_equal false
    ::SingletonPage.singleton?.must_equal true
  end

  it "::exists?" do
    SingletonPage.exists?.must_equal false
  end

  it "exports singleton status to UI" do
    SingletonPage.export[:is_singleton].must_equal true
  end

  it "prevents the over-writing of existing methods on site" do
    site_root = @site.root
    p site_root
    SingletonPage.singleton :root
    @site.root.must_equal site_root
  end

  it "namespaces modules" do
    module ::N
      class SingletonPage < ::Page; end
    end
    ::N::SingletonPage.singleton
    page = ::N::SingletonPage.create
    @site.n_singleton_page.must_equal page
  end

  describe "instances" do
    before do
      @page = SingletonPage.create
      @page.reload
    end

    it "::exists?" do
      SingletonPage.exists?.must_equal true
    end

    it "provides access to singletons through the site" do
      @site.singleton_page.must_equal @page
    end

    it "gives a ::instance method on the type" do
      SingletonPage.instance.must_equal @page
    end

    it "allows for multiple aliases to the instance" do
      @site.singleton.must_equal @page
      @site.malcom.must_equal @page
    end

    it "allows for testing if a singleton exists" do
      @site.singleton?(:singleton_page).must_equal true
      @site.singleton?(:not_singleton_page).must_equal false
    end

    it "uses a cache within a mapper scope" do
      instance1 = instance2 = instance3 = nil
      Content.scope do
        instance1 = @site.singleton
        instance2 = @site.singleton
        Content.scope(nil, true) do
          instance3 = @site.singleton
        end
      end
      instance1.object_id.must_equal instance2.object_id
      instance1.object_id.wont_equal instance3.object_id
    end
  end

  describe "sub-classes" do
    before do
      class ::SingletonSubclassPage < SingletonPage
      end
    end
    after do
      Object.send :remove_const, :SingletonSubclassPage rescue nil
    end

    it "aren't singletons" do
      SingletonSubclassPage.singleton?.must_equal false
    end
  end

  describe "boxes" do
    describe "allow" do
      before do
        ::Page.box(:stuff) { allow :Piece } # Make sure allowing pieces doesn't raise an exception
        @box = ::Page.box :sub do
          allow :SingletonPage
        end
      end

      it "allows the addition of singletons without an instance" do
        @box.allowed_types(nil).must_equal [SingletonPage]
      end
      it "restricts the addition of singletons with an instance" do
        SingletonPage.create
        @box.allowed_types(nil).must_equal []
      end
    end

    describe "allow_group" do
      before do
        @box = ::Page.box :sub do
          allow_group :singletons
        end
      end

      it "allows the addition of singletons without an instance" do
        @box.allowed_types(nil).must_equal [SingletonPage]
      end
      it "restricts the addition of singletons with an instance" do
        SingletonPage.create
        @box.allowed_types(nil).must_equal []
      end
    end

    describe "allow_subclasses" do
      before do
        @box = ::Page.box :sub do
          allow_subclasses :Page
        end
      end

      it "allows the addition of singletons without an instance" do
        @box.allowed_types(nil).must_equal [SingletonPage]
      end
      it "restricts the addition of singletons with an instance" do
        SingletonPage.create
        @box.allowed_types(nil).must_equal []
      end
    end
  end
end
