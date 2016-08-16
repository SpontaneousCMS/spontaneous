# encoding: UTF-8

require File.expand_path('../../test_helper', __FILE__)

ENV['RACK_ENV'] = 'test'
describe "Controllers" do
  include RackTestMethods
  start do
    @site_root = Dir.mktmpdir
    let(:root) { @site_root }
    S::State.delete
  end

  finish do
    ::FileUtils.rm_rf(@site_root)
  end

  class Wrappit
    def initialize(app, options = {})
      @app, @options = app, options
    end

    def call(env)
      status, headers, body = @app.call(env)
      with = @options[:with]
      wrapped = body.map { |part| [with, part, with].join("") }
      [status, headers, wrapped]
    end
  end

  before do
    @site = setup_site(root)

    class ::Page
      controller do
        use Wrappit, with: "*"
        set :something, "else"
      end
    end

    class ::SubPage < ::Page
      controller do
        get do
          settings.something
        end
      end

      controller :comments do
        use Wrappit, with: "+"
        get "/" do
          settings.something
        end
      end
    end

    class ::DeepPage < ::SubPage
      attr_accessor :dynamic_value
      layout do
        "{{ dynamic_value }}"
      end
      controller do
        post {
          page.dynamic_value = params[:value]
          render
        }
      end
      controller :comments do
        post '/' do
          params[:comment]
        end
      end
    end

    @page = ::SubPage.new(slug: 'something')
    @deep_page = ::DeepPage.new(slug: 'deep')
  end

  let(:app) { Spontaneous::Rack::Front.application(@site) }

  after do
    Object.send(:remove_const, :SubPage) rescue nil
    Object.send(:remove_const, :DeepPage) rescue nil
    teardown_site(false)
  end

  describe "requests" do
    before do
      @site.stubs(:by_path).with('/something').returns(@page)
      @site.stubs(:by_path).with('/deep').returns(@deep_page)
    end

    it "propagates settings to sub-classes" do
      get '/something'
      last_response.body.must_equal "*else*"
    end

    it "propagates settings on the base controller to named controllers" do
      get '/something/@comments'
      last_response.body.must_equal "*+else+*"
    end

    it "allows extension of existing controllers in sub-classes" do
      post '/deep/@comments', comment: "Pungent"
      last_response.body.must_equal "*+Pungent+*"
    end

    it "can set variables in the resultant render" do
      post '/deep', value: "Present"
      last_response.body.must_equal "*Present*"
    end

  end

  it "sets the type as dynamic" do
    SubPage.dynamic?(:get).must_equal true
    SubPage.dynamic?("GET").must_equal true
    @page.dynamic?(:get).must_equal true
    @page.dynamic?("GET").must_equal true
  end

  describe "PageController" do
    let(:owner) { OwnerPage.create(uid: "the_owner") }
    let(:other) { OtherPage.create(uid: "the_other") }
    let(:ctrl)  { Spontaneous::Rack::PageController.new!(@site, owner, :html) }
    let(:env)   { {Spontaneous::Rack::RENDERER => Spontaneous::Output.published_renderer(:html, @site, @site.published_revision) } }

    before do
      class ::OwnerPage < SubPage
        singleton :owner
      end
      class ::OtherPage < SubPage
        singleton :other
      end
      ctrl.env = env
      ctrl.request = Rack::Request.new(env)
      ctrl.response = Rack::Response.new
      [OwnerPage, OtherPage].each do |type|
        type.layout { "${uid}:{{success}}" }
        type.add_output :xml
      end
      @site.stubs(:other).returns(other)
    end

    after do
      owner.destroy
      other.destroy
      Object.send :remove_const, :OwnerPage rescue nil
      Object.send :remove_const, :OtherPage rescue nil
    end

    it "allows setting the output format" do
      ctrl.output :xml
      ctrl.render
      ctrl.content_type.must_equal "application/xml;charset=utf-8"
    end

    it "allows changing the rendered page" do
      ctrl.page(other)
      ctrl.render
      ctrl.body.must_equal "the_other:"
    end

    # show allows changing the page, output, status & locals without calling #render
    describe "#show" do
      it "accepts instance, format, status" do
        ctrl.show(other, :xml, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal []
      end

      it "it sets up params for #render" do
        ctrl.show(other, :xml, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal []
        ctrl.render success: "yes"
        ctrl.body.must_equal "the_other:yes"
        ctrl.content_type.must_equal "application/xml;charset=utf-8"
      end

      it "allows render to overwrite the settings" do
        ctrl.show(other, :xml, 403)
        ctrl.render owner, success: "no"
        ctrl.body.must_equal "the_owner:no"
        ctrl.content_type.must_equal "application/xml;charset=utf-8"
      end

      it "accepts singleton name (symbol), format, status" do
        ctrl.show('other', :xml, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal []
      end

      it "accepts singleton class, format, status" do
        ctrl.show(OtherPage, :xml, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal []
      end

      it "accepts singleton name (string), status" do
        ctrl.show('other', 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts singleton name (symbol), status" do
        ctrl.show(:other, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts singleton class, status" do
        ctrl.show(OtherPage, 410)
        ctrl.status.must_equal 410
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts singleton name" do
        ctrl.show('other')
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts singleton name" do
        ctrl.show(:other)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts singleton class" do
        ctrl.show(OtherPage)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts instance (Content)" do
        ctrl.show(other)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts instance (Content), status" do
        ctrl.show(other, 411)
        ctrl.status.must_equal 411
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts status" do
        ctrl.show(403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end
    end

    describe "#render" do
      it "renders the owning page by default" do
        ctrl.render
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_owner:"
      end

      it "accepts instance, format, status, locals" do
        ctrl.render(other, :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton name (string), format, status, locals" do
        ctrl.render('other', :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton name (symbol), format, status, locals" do
        ctrl.render(:other, :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton class, format, status, locals" do
        ctrl.render(OtherPage, :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton name (string), status, locals" do
        ctrl.render('other', 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton name (symbol), status, locals" do
        ctrl.render(:other, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton class, status, locals" do
        ctrl.render(OtherPage, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts singleton name (string)" do
        ctrl.render('other')
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts singleton name (symbol)" do
        ctrl.render(:other)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts singleton class" do
        ctrl.render(OtherPage)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts singleton name (string), status" do
        ctrl.render('other', 409)
        ctrl.status.must_equal 409
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts singleton name (symbol), status" do
        ctrl.render(:other, 410)
        ctrl.status.must_equal 410
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts singleton class, status" do
        ctrl.render(OtherPage, 410)
        ctrl.status.must_equal 410
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts instance (Content)" do
        ctrl.render(other)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts instance (Content), status" do
        ctrl.render(other, 411)
        ctrl.status.must_equal 411
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:"
      end

      it "accepts locals" do
        ctrl.render(success: "yes")
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_owner:yes"
      end

      it "accepts singleton name (symbol), locals" do
        ctrl.render(:other, success: "yes")
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_other:yes"
      end

      it "accepts status" do
        ctrl.render(403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_owner:"
      end

      it "accepts status, locals" do
        ctrl.render(403, success: "no")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "the_owner:no"
      end
    end
  end
end
