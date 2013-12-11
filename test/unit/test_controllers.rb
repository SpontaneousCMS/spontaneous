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

  let(:app) { Spontaneous::Rack::Front.application }

  after do
    Object.send(:remove_const, :SubPage) rescue nil
    Object.send(:remove_const, :DeepPage) rescue nil
    teardown_site(false)
  end

  describe "requests" do
    before do
      Spontaneous::Site.stubs(:by_path).with('/something').returns(@page)
      Spontaneous::Site.stubs(:by_path).with('/deep').returns(@deep_page)
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
    let(:owner) { SubPage.new(uid: "owner") }
    let(:other) { SubPage.new(uid: "other") }
    let(:ctrl)  { Spontaneous::Rack::PageController.new!(owner, :html) }
    let(:env)   { {Spontaneous::Rack::RENDERER => Spontaneous::Output.published_renderer} }

    before do
      ctrl.env = env
      ctrl.request = Rack::Request.new(env)
      ctrl.response = Rack::Response.new
      SubPage.layout { "${uid}:{{success}}" }
      SubPage.add_output :xml
      Spontaneous::Site.stubs(:by_uid).with('other', Content).returns(other)
      Spontaneous::Site.stubs(:by_uid).with(:other, Content).returns(other)
    end

    it "allows setting the output format" do
      ctrl.output :xml
      ctrl.render
      ctrl.content_type.must_equal "application/xml;charset=utf-8"
    end

    it "allows changing the rendered page" do
      ctrl.page(other)
      ctrl.render
      ctrl.body.must_equal "other:"
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
        ctrl.body.must_equal "other:yes"
        ctrl.content_type.must_equal "application/xml;charset=utf-8"
      end

      it "allows render to overwrite the settings" do
        ctrl.show(other, :xml, 403)
        ctrl.render owner, success: "no"
        ctrl.body.must_equal "owner:no"
        ctrl.content_type.must_equal "application/xml;charset=utf-8"
      end

      it "accepts uid (string), format, status" do
        ctrl.show('other', :xml, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal []
      end

      it "accepts uid (symbol), format, status" do
        ctrl.show(:other, :xml, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal []
      end

      it "accepts uid (string), status" do
        ctrl.show('other', 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts uid (symbol), status" do
        ctrl.show(:other, 403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts uid (string)" do
        ctrl.show('other')
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts uid (symbol)" do
        ctrl.show(:other)
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

      it "accepts uid (string), status" do
        ctrl.show('other', 409)
        ctrl.status.must_equal 409
        ctrl.output.must_equal :html
        ctrl.body.must_equal []
      end

      it "accepts uid (symbol), status" do
        ctrl.show(:other, 410)
        ctrl.status.must_equal 410
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
        ctrl.body.must_equal "owner:"
      end

      it "accepts instance, format, status, locals" do
        ctrl.render(other, :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "other:yes"
      end

      it "accepts uid (string), format, status, locals" do
        ctrl.render('other', :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "other:yes"
      end

      it "accepts uid (symbol), format, status, locals" do
        ctrl.render(:other, :xml, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :xml
        ctrl.body.must_equal "other:yes"
      end

      it "accepts uid (string), status, locals" do
        ctrl.render('other', 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:yes"
      end

      it "accepts uid (symbol), status, locals" do
        ctrl.render(:other, 403, success: "yes")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:yes"
      end

      it "accepts uid (string)" do
        ctrl.render('other')
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:"
      end

      it "accepts uid (symbol)" do
        ctrl.render(:other)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:"
      end

      it "accepts instance (Content)" do
        ctrl.render(other)
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:"
      end

      it "accepts uid (string), status" do
        ctrl.render('other', 409)
        ctrl.status.must_equal 409
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:"
      end

      it "accepts uid (symbol), status" do
        ctrl.render(:other, 410)
        ctrl.status.must_equal 410
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:"
      end

      it "accepts instance (Content), status" do
        ctrl.render(other, 411)
        ctrl.status.must_equal 411
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:"
      end

      it "accepts locals" do
        ctrl.render(success: "yes")
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "owner:yes"
      end

      it "accepts uid (string), locals" do
        ctrl.render('$other', success: "yes")
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:yes"
      end

      it "accepts uid (symbol), locals" do
        ctrl.render(:other, success: "yes")
        ctrl.status.must_equal 200
        ctrl.output.must_equal :html
        ctrl.body.must_equal "other:yes"
      end

      it "accepts status" do
        ctrl.render(403)
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "owner:"
      end

      it "accepts status, locals" do
        ctrl.render(403, success: "no")
        ctrl.status.must_equal 403
        ctrl.output.must_equal :html
        ctrl.body.must_equal "owner:no"
      end
    end
  end
end
